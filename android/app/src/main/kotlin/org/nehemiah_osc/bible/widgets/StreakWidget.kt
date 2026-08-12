package org.nehemiah_osc.bible.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import org.nehemiah_osc.bible.R

/**
 * Default flame, mirroring `kDefaultStreakEmoji` in
 * `lib/core/settings/app_settings.dart`.
 *
 * Duplicated rather than read from prefs-or-nothing so that a widget added
 * before the app has ever run still shows a flame instead of an empty square
 * where the emoji should be.
 */
private const val DEFAULT_STREAK_EMOJI = "🔥"

/** Two cells square — what this widget is designed at. */
private val REFERENCE_BOX = WidgetBox(widthDp = 110, heightDp = 110)

private const val EMOJI_SP = 30f
private const val COUNT_SP = 26f
private const val LABEL_SP = 12f
private const val PADDING_DP = 10f

/**
 * A one-cell streak is the number and nothing else — at that size the emoji
 * and the word "days" together leave no room for the thing they describe.
 */
private const val MIN_HEIGHT_FOR_EMOJI_DP = 92
private const val MIN_HEIGHT_FOR_LABEL_DP = 68

class StreakWidget : StyledWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val count = widgetData.getInt(WidgetKeys.STREAK_COUNT, 0)
        val emoji = widgetData.getString(WidgetKeys.STREAK_EMOJI, null)
            ?.takeIf { it.isNotBlank() }
            ?: DEFAULT_STREAK_EMOJI

        // Falls back to the raw int only before the first refresh, when the
        // numeral-aware label has never been written. After that the label is
        // authoritative — it may be in Ge'ez, which `count` cannot express.
        val countLabel = widgetData.getString(WidgetKeys.STREAK_COUNT_LABEL, null)
            ?.takeIf { it.isNotBlank() }
            ?: count.toString()
        val suffix = widgetData.getString(WidgetKeys.STREAK_SUFFIX, null).orEmpty()
        val deepLink = widgetData.getString(WidgetKeys.STREAK_DEEPLINK, null)

        val style = widgetData.widgetStyle(
            WidgetKeys.STREAK_STYLE_PREFIX,
            defaultTheme = WidgetTheme.AUTO,
        )
        val palette = WidgetPalette.of(context, style.theme)

        appWidgetIds.forEach { widgetId ->
            val box = appWidgetManager.boxOf(widgetId, REFERENCE_BOX)
            val grow = box.growth(REFERENCE_BOX.widthDp, REFERENCE_BOX.heightDp)
            val scale = grow * style.textFactor

            val views = RemoteViews(context.packageName, R.layout.widget_streak).apply {
                applyCard(style, palette)

                setTextViewText(R.id.streak_emoji, emoji)
                setTextViewText(R.id.streak_count, countLabel)
                setTextViewText(R.id.streak_label, suffix)

                setTextColor(R.id.streak_count, palette.text)
                setTextColor(R.id.streak_label, palette.muted)

                setPaddingDp(context, R.id.streak_content, PADDING_DP * grow)

                // The emoji follows the widget's size but not the user's text
                // scale: it is decoration, and growing it along with "large
                // text" pushes the number it decorates off a small widget.
                setTextSizeSp(R.id.streak_emoji, EMOJI_SP * grow)
                setTextSizeSp(R.id.streak_count, COUNT_SP * scale)
                setTextSizeSp(R.id.streak_label, LABEL_SP * scale)

                show(
                    R.id.streak_emoji,
                    style.showDetail && box.heightDp >= MIN_HEIGHT_FOR_EMOJI_DP,
                )
                show(
                    R.id.streak_label,
                    style.showLabel &&
                        suffix.isNotBlank() &&
                        box.heightDp >= MIN_HEIGHT_FOR_LABEL_DP,
                )

                setDeepLinkOnRoot(context, R.id.widget_root, deepLink, widgetId)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
