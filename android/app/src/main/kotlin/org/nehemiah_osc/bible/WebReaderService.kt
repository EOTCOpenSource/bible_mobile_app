package org.nehemiah_osc.bible

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

/**
 * Keeps the Local Web Reader's HTTP server reachable while the app is in the
 * background.
 *
 * The server itself is Dart — a `shelf` server on the Flutter engine's event
 * loop — so this service does not serve anything. It exists for the two things
 * only a foreground service can do: stop Android from freezing or killing the
 * process once the app leaves the screen, and keep its network access alive in
 * Doze. Without it, "read on my laptop while the phone is in my pocket" stops
 * working a few minutes after the screen goes off.
 *
 * The engine dies with the activity, so swiping the app out of recents ends the
 * server too. That is deliberate: it is the one gesture a user means as "close
 * it", and the notification's Stop action covers every other case.
 */
class WebReaderService : Service() {

    companion object {
        const val ACTION_START = "org.nehemiah_osc.bible.WEB_READER_START"
        const val ACTION_STOP = "org.nehemiah_osc.bible.WEB_READER_STOP"

        const val EXTRA_TITLE = "title"
        const val EXTRA_URL = "url"
        const val EXTRA_STOP_LABEL = "stopLabel"

        private const val CHANNEL_ID = "web_reader_channel"
        private const val NOTIFICATION_ID = 7777

        /**
         * Invoked when the user taps Stop on the notification.
         *
         * Set by [MainActivity] so the tap can reach the Dart side, which owns
         * the socket. The service cannot close the server itself.
         */
        @Volatile
        var onStopRequested: (() -> Unit)? = null
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                // Ask Dart to close the socket first; the notification going
                // away before the server does would be a lie.
                Handler(Looper.getMainLooper()).post {
                    onStopRequested?.invoke()
                }
                stopSelf()
            }
            else -> {
                val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Local Web Reader"
                val url = intent?.getStringExtra(EXTRA_URL) ?: ""
                val stopLabel = intent?.getStringExtra(EXTRA_STOP_LABEL) ?: "Stop"
                startInForeground(title, url, stopLabel)
            }
        }
        // Not sticky: a restart by the OS would bring back the notification
        // without the Dart server behind it.
        return START_NOT_STICKY
    }

    private fun startInForeground(title: String, url: String, stopLabel: String) {
        createChannel()

        // Tapping the notification body returns to the app, where the card has
        // the address and the QR code.
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val openPending = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val stopPending = PendingIntent.getService(
            this,
            1,
            Intent(this, WebReaderService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val notification = builder
            .setContentTitle(title)
            .setContentText(url)
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentIntent(openPending)
            .setOngoing(true)
            .setStyle(Notification.BigTextStyle().bigText(url))
            .addAction(
                Notification.Action.Builder(
                    null,
                    stopLabel,
                    stopPending,
                ).build()
            )
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // `dataSync` is the type that fits a server the user explicitly
            // started and can see the address of.
            startForeground(
                NOTIFICATION_ID,
                notification,
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "Local Web Reader",
                // Low: this is a status line, not an interruption. It still
                // cannot be swiped away while the server is running.
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shown while the Bible is being served to other devices"
                setShowBadge(false)
            }
        )
    }

    override fun onDestroy() {
        onStopRequested = null
        super.onDestroy()
    }
}
