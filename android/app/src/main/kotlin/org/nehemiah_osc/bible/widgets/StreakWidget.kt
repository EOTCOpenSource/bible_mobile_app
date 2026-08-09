package org.nehemiah_osc.bible.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
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

class StreakWidget : HomeWidgetProvider() {

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

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_streak).apply {
                setTextViewText(R.id.streak_emoji, emoji)
                setTextViewText(R.id.streak_count, countLabel)
                setTextViewText(R.id.streak_label, suffix)

                setDeepLinkOnRoot(context, R.id.widget_root, deepLink, widgetId)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
