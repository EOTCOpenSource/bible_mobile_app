package org.nehemiah_osc.bible.widgets

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

/**
 * The shared-preference keys the Dart side writes.
 *
 * The other half of the contract in
 * `lib/core/home_widget/home_widget_data.dart`. A key renamed on one side and
 * not the other does not fail loudly — `getString` simply returns the default
 * and the widget shows placeholder text forever — so the two lists are kept
 * literal and adjacent rather than derived.
 */
internal object WidgetKeys {
    const val VERSE_TEXT = "verse_text"
    const val VERSE_REF = "verse_ref"
    const val VERSE_REF_SHORT = "verse_ref_short"
    const val VERSE_DEEPLINK = "verse_deeplink"

    const val CONTINUE_BOOK = "continue_book"
    const val CONTINUE_REF = "continue_ref"
    const val CONTINUE_PROGRESS = "continue_progress"
    const val CONTINUE_DEEPLINK = "continue_deeplink"

    const val STREAK_COUNT = "streak_count"
    const val STREAK_COUNT_LABEL = "streak_count_label"
    const val STREAK_EMOJI = "streak_emoji"
    const val STREAK_SUFFIX = "streak_suffix"
    const val STREAK_DEEPLINK = "streak_deeplink"

    /**
     * The prefixes each widget's *style* keys are built from — see
     * [widgetStyle] and `HomeWidgetKind` in `widget_appearance.dart`.
     *
     * Style lives under its own prefixes rather than beside the content keys
     * above because it is written on a different clock: content on every app
     * resume, style only when the user changes it.
     */
    const val VERSE_STYLE_PREFIX = "verse"
    const val CONTINUE_STYLE_PREFIX = "continue"
    const val STREAK_STYLE_PREFIX = "streak"
}

/**
 * Falls back to launching the app when [deepLink] is blank.
 *
 * A widget whose tap does nothing reads as broken. Before the first refresh
 * every deep link is empty, which is exactly when a new user is most likely to
 * tap one, so that case opens the app rather than swallowing the touch.
 */
internal fun RemoteViews.setDeepLinkOnRoot(
    context: Context,
    viewId: Int,
    deepLink: String?,
    requestCode: Int,
) {
    val intent = if (deepLink.isNullOrBlank()) {
        context.packageManager.getLaunchIntentForPackage(context.packageName)
    } else {
        Intent(Intent.ACTION_VIEW, Uri.parse(deepLink)).setPackage(context.packageName)
    } ?: return

    // FLAG_IMMUTABLE is required from API 31 and harmless before it — nothing
    // here needs the receiver to fill anything in.
    val pending = PendingIntent.getActivity(
        context,
        requestCode,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
    setOnClickPendingIntent(viewId, pending)
}
