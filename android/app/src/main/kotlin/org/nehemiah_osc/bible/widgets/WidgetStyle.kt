package org.nehemiah_osc.bible.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import org.nehemiah_osc.bible.R
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * How a widget is drawn, as opposed to what it says.
 *
 * The other half of `lib/core/home_widget/widget_appearance.dart`. Every value
 * is written by the settings page and read back here; the defaults below have
 * to match the Dart defaults exactly, because a widget added before the app
 * has ever been opened reads keys that were never written and would otherwise
 * look nothing like the preview the user was shown.
 */
internal data class WidgetStyle(
    val theme: WidgetTheme,
    val textFactor: Float,
    val opacity: Int,
    val showLabel: Boolean,
    val showDetail: Boolean,
)

internal enum class WidgetTheme {
    /** Follows the launcher's own night mode, which is what most widgets do. */
    AUTO,
    LIGHT,
    DARK,

    /** The maroon card the app's home screen draws its daily verse on. */
    BRAND,
}

/**
 * The preference keys a style is stored under, built from a per-widget prefix.
 *
 * Prefixes are `verse`, `continue` and `streak`, matching `HomeWidgetKind` in
 * Dart. Kept as a formatter rather than twelve constants so the two sides
 * cannot drift one key at a time.
 */
private fun styleKey(prefix: String, name: String) = "${prefix}_style_$name"

/** Reads the style stored under [prefix], falling back to [defaultTheme]. */
internal fun SharedPreferences.widgetStyle(
    prefix: String,
    defaultTheme: WidgetTheme,
): WidgetStyle {
    val theme = when (getString(styleKey(prefix, "theme"), null)) {
        "light" -> WidgetTheme.LIGHT
        "dark" -> WidgetTheme.DARK
        "brand" -> WidgetTheme.BRAND
        "auto" -> WidgetTheme.AUTO
        else -> defaultTheme
    }
    val textFactor = when (getString(styleKey(prefix, "scale"), null)) {
        "small" -> 0.85f
        "large" -> 1.18f
        else -> 1.0f
    }
    // Booleans are stored as 0/1 ints: getBoolean on a key that was never
    // written returns false, which would hide the label on a fresh install,
    // while an int default can say "not written" and mean "show it".
    return WidgetStyle(
        theme = theme,
        textFactor = textFactor,
        opacity = getInt(styleKey(prefix, "opacity"), 100).coerceIn(0, 100),
        showLabel = getInt(styleKey(prefix, "label"), 1) != 0,
        showDetail = getInt(styleKey(prefix, "detail"), 1) != 0,
    )
}

/**
 * The colours and card drawable one theme resolves to.
 *
 * Resolved here rather than left to resource qualifiers because a user who
 * pinned a widget to "light" must keep a light widget on a dark launcher, and
 * a values-night override cannot tell the two apart.
 */
internal class WidgetPalette private constructor(
    val card: Int,
    val text: Int,
    val muted: Int,
    val accent: Int,
    val track: Int,
    val isBrand: Boolean,
) {
    companion object {
        fun of(context: Context, theme: WidgetTheme): WidgetPalette {
            val resolved = if (theme == WidgetTheme.AUTO) {
                if (context.isNightMode()) WidgetTheme.DARK else WidgetTheme.LIGHT
            } else {
                theme
            }
            return when (resolved) {
                WidgetTheme.BRAND -> WidgetPalette(
                    card = R.drawable.widget_card_brand,
                    text = context.getColor(R.color.widget_brand_text),
                    muted = context.getColor(R.color.widget_brand_muted),
                    accent = context.getColor(R.color.widget_brand_accent),
                    track = context.getColor(R.color.widget_brand_track),
                    isBrand = true,
                )
                WidgetTheme.DARK -> WidgetPalette(
                    card = R.drawable.widget_card_dark,
                    text = context.getColor(R.color.widget_dark_text),
                    muted = context.getColor(R.color.widget_dark_muted),
                    accent = context.getColor(R.color.widget_dark_accent),
                    track = context.getColor(R.color.widget_dark_track),
                    isBrand = false,
                )
                // AUTO has already been resolved to one of the two above.
                else -> WidgetPalette(
                    card = R.drawable.widget_card_light,
                    text = context.getColor(R.color.widget_light_text),
                    muted = context.getColor(R.color.widget_light_muted),
                    accent = context.getColor(R.color.widget_light_accent),
                    track = context.getColor(R.color.widget_light_track),
                    isBrand = false,
                )
            }
        }
    }
}

private fun Context.isNightMode(): Boolean =
    (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
        Configuration.UI_MODE_NIGHT_YES

/**
 * The size the launcher has actually given a widget, in dp.
 *
 * [OPTION_APPWIDGET_MIN_WIDTH][AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH] and
 * `OPTION_APPWIDGET_MIN_HEIGHT` are the portrait width and the landscape
 * height — between them, the smallest the widget will ever be drawn at without
 * the user resizing it again. Laying out for that box means a rotation cannot
 * clip anything; using the MAX pair would look better in one orientation and
 * overflow in the other.
 */
internal data class WidgetBox(val widthDp: Int, val heightDp: Int) {

    /**
     * How much bigger than [refWidthDp] × [refHeightDp] this widget is, as a
     * multiplier for text and padding.
     *
     * Damped to 45% of the raw ratio and clamped: a widget stretched to twice
     * its default size wants noticeably larger text, not text twice the size —
     * past a point the extra room is better spent on more lines of verse.
     */
    fun growth(refWidthDp: Int, refHeightDp: Int): Float {
        val raw = min(
            widthDp / refWidthDp.toFloat(),
            heightDp / refHeightDp.toFloat(),
        )
        return (1f + (raw - 1f) * 0.45f).coerceIn(0.72f, 1.45f)
    }
}

/**
 * Falls back to [fallback] when the launcher has not reported a size yet,
 * which it has not on the very first update after the widget is dropped.
 */
internal fun AppWidgetManager.boxOf(widgetId: Int, fallback: WidgetBox): WidgetBox {
    val options = getAppWidgetOptions(widgetId) ?: return fallback
    val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
    val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
    return WidgetBox(
        widthDp = if (width > 0) width else fallback.widthDp,
        heightDp = if (height > 0) height else fallback.heightDp,
    )
}

// ── RemoteViews helpers ─────────────────────────────────────────────────────

internal fun RemoteViews.show(viewId: Int, visible: Boolean) {
    setViewVisibility(viewId, if (visible) View.VISIBLE else View.GONE)
}

internal fun RemoteViews.setTextSizeSp(viewId: Int, sp: Float) {
    setTextViewTextSize(viewId, TypedValue.COMPLEX_UNIT_SP, sp)
}

internal fun RemoteViews.setMaxLines(viewId: Int, lines: Int) {
    setInt(viewId, "setMaxLines", max(1, lines))
}

internal fun RemoteViews.setPaddingDp(context: Context, viewId: Int, dp: Float) {
    val px = (dp * context.resources.displayMetrics.density).roundToInt()
    setViewPadding(viewId, px, px, px, px)
}

/**
 * Tints a white bar drawable. `setColorFilter(int)` is `SRC_ATOP`, so the
 * shape's own alpha survives and its colour is replaced wholesale — which is
 * why every palette's track colour is opaque.
 */
internal fun RemoteViews.tint(viewId: Int, color: Int) {
    setInt(viewId, "setColorFilter", color)
}

/**
 * Paints the card behind a widget: the palette's drawable, the user's opacity,
 * and the decorative disc that belongs to the brand card only.
 */
internal fun RemoteViews.applyCard(style: WidgetStyle, palette: WidgetPalette) {
    setImageViewResource(R.id.widget_bg, palette.card)
    // Only the card fades. The text never does — a widget the user cannot read
    // is not a style, it is a bug.
    setInt(R.id.widget_bg, "setImageAlpha", style.opacity * 255 / 100)
    show(R.id.widget_disc, palette.isBrand)
}
