package org.nehemiah_osc.bible.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import org.nehemiah_osc.bible.R

/**
 * The size the card is designed at — four cells across, two down.
 *
 * Everything below is expressed as a multiple of how far the widget's real box
 * is from this one, so there is a single place to change what "normal" means.
 */
private val REFERENCE_BOX = WidgetBox(widthDp = 250, heightDp = 110)

/** Base text sizes at [REFERENCE_BOX], in sp, matching daily_verse_card.dart. */
private const val LABEL_SP = 11f
private const val SHORT_REF_SP = 9f
private const val VERSE_SP = 14f
private const val REF_SP = 12f

private const val PADDING_DP = 14f

/**
 * The height below which a row stops earning its space.
 *
 * A one-cell-tall daily verse is all verse: the tag and the reference are
 * worth two lines of scripture only once there are lines to spare.
 */
private const val MIN_HEIGHT_FOR_HEADER_DP = 85
private const val MIN_HEIGHT_FOR_REF_DP = 62

/** Below this the corner reference collides with the tag beside it. */
private const val MIN_WIDTH_FOR_SHORT_REF_DP = 135

/**
 * The day's verse, tapping through to the verse itself.
 *
 * All text arrives pre-localised and pre-truncated from Dart — see
 * `buildHomeWidgetData`. Nothing here decides how anything reads, because this
 * runs in the launcher's process where the app's strings and the Ge'ez numeral
 * helpers do not exist. What this *does* decide is how it looks: the palette,
 * the text sizes and how many lines fit are all functions of the box the
 * launcher gave the widget and the style the user chose.
 */
class DailyVerseWidget : StyledWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val verseText = widgetData.getString(WidgetKeys.VERSE_TEXT, null).orEmpty()
        val verseRef = widgetData.getString(WidgetKeys.VERSE_REF, null).orEmpty()
        val shortRef = widgetData.getString(WidgetKeys.VERSE_REF_SHORT, null).orEmpty()
        val deepLink = widgetData.getString(WidgetKeys.VERSE_DEEPLINK, null)

        // Brand by default: the widget is the home screen's daily verse card,
        // and that card is maroon.
        val style = widgetData.widgetStyle(
            WidgetKeys.VERSE_STYLE_PREFIX,
            defaultTheme = WidgetTheme.BRAND,
        )
        val palette = WidgetPalette.of(context, style.theme)

        appWidgetIds.forEach { widgetId ->
            val box = appWidgetManager.boxOf(widgetId, REFERENCE_BOX)
            val grow = box.growth(REFERENCE_BOX.widthDp, REFERENCE_BOX.heightDp)
            val scale = grow * style.textFactor

            val views = RemoteViews(context.packageName, R.layout.widget_daily_verse).apply {
                applyCard(style, palette)

                // Empty means the app has not run since install, or the verse
                // failed to resolve. Swap in a prompt rather than showing an
                // empty card that looks like a rendering bug.
                val hasVerse = verseText.isNotBlank()
                show(R.id.verse_content, hasVerse)
                show(R.id.verse_empty, !hasVerse)

                setTextViewText(R.id.verse_text, verseText)
                setTextViewText(R.id.verse_ref, verseRef)
                setTextViewText(R.id.verse_ref_short, shortRef)

                setTextColor(R.id.verse_text, palette.text)
                setTextColor(R.id.verse_label, palette.accent)
                setTextColor(R.id.verse_ref, palette.accent)
                setTextColor(R.id.verse_ref_short, palette.muted)
                setTextColor(R.id.verse_empty, palette.muted)

                val padding = PADDING_DP * grow
                setPaddingDp(context, R.id.verse_content, padding)
                setPaddingDp(context, R.id.verse_empty, padding)

                val verseSp = VERSE_SP * scale
                setTextSizeSp(R.id.verse_text, verseSp)
                setTextSizeSp(R.id.verse_label, LABEL_SP * scale)
                setTextSizeSp(R.id.verse_ref, REF_SP * scale)
                setTextSizeSp(R.id.verse_ref_short, SHORT_REF_SP * scale)
                setTextSizeSp(R.id.verse_empty, REF_SP * scale)

                val showHeader =
                    style.showLabel && box.heightDp >= MIN_HEIGHT_FOR_HEADER_DP
                val showRef = style.showDetail && box.heightDp >= MIN_HEIGHT_FOR_REF_DP
                show(R.id.verse_header, showHeader)
                show(R.id.verse_ref, showRef)
                show(
                    R.id.verse_ref_short,
                    box.widthDp >= MIN_WIDTH_FOR_SHORT_REF_DP && shortRef.isNotBlank(),
                )

                setMaxLines(
                    R.id.verse_text,
                    verseLines(box, padding, verseSp, showHeader, showRef, scale),
                )

                setDeepLinkOnRoot(context, R.id.widget_root, deepLink, widgetId)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /**
     * How many lines of verse the leftover height holds.
     *
     * Computed rather than fixed because `layout_weight` alone only decides how
     * much room the text *may* use — `maxLines` decides how much it takes, and
     * a maxLines tuned for two cells leaves a four-cell widget two thirds
     * empty. The 1.42 is the 1.35 line-spacing multiplier in the layout plus
     * the Ethiopic face's own leading.
     */
    private fun verseLines(
        box: WidgetBox,
        paddingDp: Float,
        verseSp: Float,
        showHeader: Boolean,
        showRef: Boolean,
        scale: Float,
    ): Int {
        val chrome = paddingDp * 2 +
            (if (showHeader) LABEL_SP * scale * 1.6f + 10f else 0f) +
            (if (showRef) REF_SP * scale * 1.6f + 8f else 0f)
        val available = box.heightDp - chrome
        return (available / (verseSp * 1.42f)).toInt().coerceIn(1, 14)
    }
}
