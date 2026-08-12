package org.nehemiah_osc.bible.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import org.nehemiah_osc.bible.R

/** Clip drawables are addressed in ten-thousandths, not percent. */
private const val CLIP_LEVEL_MAX = 10_000

/** Four cells across, one down — what this widget is designed at. */
private val REFERENCE_BOX = WidgetBox(widthDp = 250, heightDp = 60)

private const val LABEL_SP = 10f
private const val BOOK_SP = 16f
private const val REF_SP = 12f
private const val PADDING_DP = 14f

/** Below these the row in question is costing more than it says. */
private const val MIN_HEIGHT_FOR_LABEL_DP = 55
private const val MIN_HEIGHT_FOR_BAR_DP = 72

/** Above this there is room to let a long Amharic book name wrap. */
private const val MIN_HEIGHT_FOR_TWO_LINE_BOOK_DP = 95

class ContinueReadingWidget : StyledWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val book = widgetData.getString(WidgetKeys.CONTINUE_BOOK, null).orEmpty()
        val ref = widgetData.getString(WidgetKeys.CONTINUE_REF, null).orEmpty()
        val progress = widgetData.getInt(WidgetKeys.CONTINUE_PROGRESS, 0).coerceIn(0, 100)
        val deepLink = widgetData.getString(WidgetKeys.CONTINUE_DEEPLINK, null)

        val style = widgetData.widgetStyle(
            WidgetKeys.CONTINUE_STYLE_PREFIX,
            defaultTheme = WidgetTheme.AUTO,
        )
        val palette = WidgetPalette.of(context, style.theme)

        appWidgetIds.forEach { widgetId ->
            val box = appWidgetManager.boxOf(widgetId, REFERENCE_BOX)
            val grow = box.growth(REFERENCE_BOX.widthDp, REFERENCE_BOX.heightDp)
            val scale = grow * style.textFactor

            val views = RemoteViews(context.packageName, R.layout.widget_continue_reading).apply {
                applyCard(style, palette)

                // A fresh install has no reading history at all. Offering
                // "start reading" beats an empty card with a 0% bar.
                val hasBook = book.isNotBlank()
                show(R.id.continue_content, hasBook)
                show(R.id.continue_empty, !hasBook)

                setTextViewText(R.id.continue_book, book)
                setTextViewText(R.id.continue_ref, ref)

                setTextColor(R.id.continue_book, palette.text)
                setTextColor(R.id.continue_label, palette.muted)
                setTextColor(R.id.continue_ref, palette.accent)
                setTextColor(R.id.continue_empty, palette.muted)
                tint(R.id.continue_track, palette.track)
                tint(R.id.continue_progress, palette.accent)

                val padding = PADDING_DP * grow
                setPaddingDp(context, R.id.continue_content, padding)
                setPaddingDp(context, R.id.continue_empty, padding)

                setTextSizeSp(R.id.continue_label, LABEL_SP * scale)
                setTextSizeSp(R.id.continue_book, BOOK_SP * scale)
                setTextSizeSp(R.id.continue_ref, REF_SP * scale)
                setTextSizeSp(R.id.continue_empty, REF_SP * scale)

                show(
                    R.id.continue_label,
                    style.showLabel && box.heightDp >= MIN_HEIGHT_FOR_LABEL_DP,
                )
                show(
                    R.id.continue_bar,
                    style.showDetail && box.heightDp >= MIN_HEIGHT_FOR_BAR_DP,
                )
                setMaxLines(
                    R.id.continue_book,
                    if (box.heightDp >= MIN_HEIGHT_FOR_TWO_LINE_BOOK_DP) 2 else 1,
                )

                // setImageViewResource would reset the level, so the level is
                // set on the already-inflated drawable via its ImageView.
                setInt(
                    R.id.continue_progress,
                    "setImageLevel",
                    progress * CLIP_LEVEL_MAX / 100,
                )

                setDeepLinkOnRoot(context, R.id.widget_root, deepLink, widgetId)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
