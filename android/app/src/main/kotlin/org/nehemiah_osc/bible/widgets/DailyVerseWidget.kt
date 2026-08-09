package org.nehemiah_osc.bible.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.nehemiah_osc.bible.R

/**
 * The day's verse, tapping through to the verse itself.
 *
 * All text arrives pre-localised and pre-truncated from Dart — see
 * `buildHomeWidgetData`. Nothing here decides how anything reads, because this
 * runs in the launcher's process where the app's strings and the Ge'ez numeral
 * helpers do not exist.
 */
class DailyVerseWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val verseText = widgetData.getString(WidgetKeys.VERSE_TEXT, null).orEmpty()
        val verseRef = widgetData.getString(WidgetKeys.VERSE_REF, null).orEmpty()
        val deepLink = widgetData.getString(WidgetKeys.VERSE_DEEPLINK, null)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_daily_verse).apply {
                // Empty means the app has not run since install, or the verse
                // failed to resolve. Swap in a prompt rather than showing an
                // empty card that looks like a rendering bug.
                val hasVerse = verseText.isNotBlank()
                setViewVisibility(R.id.verse_text, if (hasVerse) View.VISIBLE else View.GONE)
                setViewVisibility(R.id.verse_empty, if (hasVerse) View.GONE else View.VISIBLE)

                setTextViewText(R.id.verse_text, verseText)
                setTextViewText(R.id.verse_ref, verseRef)
                setDeepLinkOnRoot(context, R.id.widget_root, deepLink, widgetId)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
