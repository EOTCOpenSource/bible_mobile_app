package org.nehemiah_osc.bible.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * A [HomeWidgetProvider] that redraws itself when it is resized.
 *
 * Without this, `onUpdate` runs when the data changes and never again — so a
 * widget dragged from two cells to four keeps the text sizes, line count and
 * padding it was given at its old size, which is what "the widget does not
 * respond to resizing" looks like from the home screen. The launcher does tell
 * us: it delivers `ACTION_APPWIDGET_OPTIONS_CHANGED` with the new box, and all
 * three widgets want exactly the same response to it.
 */
abstract class StyledWidgetProvider : HomeWidgetProvider() {

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        // The same path an ordinary update takes, for this one widget: the
        // size is read back from the manager inside onUpdate, so nothing here
        // has to unpack newOptions.
        onUpdate(
            context,
            appWidgetManager,
            intArrayOf(appWidgetId),
            HomeWidgetPlugin.getData(context),
        )
    }
}
