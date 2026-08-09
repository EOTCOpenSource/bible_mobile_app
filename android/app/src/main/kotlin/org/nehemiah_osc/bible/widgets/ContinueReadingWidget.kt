package org.nehemiah_osc.bible.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.nehemiah_osc.bible.R

/** Clip drawables are addressed in ten-thousandths, not percent. */
private const val CLIP_LEVEL_MAX = 10_000

class ContinueReadingWidget : HomeWidgetProvider() {

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

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_continue_reading).apply {
                // A fresh install has no reading history at all. Offering
                // "start reading" beats an empty card with a 0% bar.
                val hasBook = book.isNotBlank()
                setViewVisibility(R.id.continue_label, if (hasBook) View.VISIBLE else View.GONE)
                setViewVisibility(R.id.continue_book, if (hasBook) View.VISIBLE else View.GONE)
                setViewVisibility(R.id.continue_ref, if (hasBook) View.VISIBLE else View.GONE)
                setViewVisibility(R.id.continue_progress, if (hasBook) View.VISIBLE else View.GONE)
                setViewVisibility(R.id.continue_empty, if (hasBook) View.GONE else View.VISIBLE)

                setTextViewText(R.id.continue_book, book)
                setTextViewText(R.id.continue_ref, ref)

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
