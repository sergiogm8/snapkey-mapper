package com.sgm.snapkeymapper

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.SystemClock
import android.provider.AlarmClock
import android.provider.Settings
import android.view.KeyEvent

data class ActionExecutionResult(
    val actionLabel: String,
    val success: Boolean,
    val errorMessage: String? = null,
)

/**
 * Reads the configured action fresh from [ConfigStore] on every call, so a config change from the
 * UI applies on the very next fire.
 *
 * Launch strategy: a direct `startActivity()` call from a background context (the real DND-trigger
 * path) is silently blocked by Android's Background Activity Launch restrictions unless "Display
 * over other apps" (`SYSTEM_ALERT_WINDOW`) is granted, which is a documented BAL exemption. Without
 * it, falls back to launching via a notification (full-screen intent + tap-to-open).
 */
object ActionExecutor {
    private const val TRIGGER_CHANNEL_ID = "snapkey_mapper_trigger"
    private const val TRIGGER_NOTIFICATION_ID = 1002

    fun execute(context: Context): ActionExecutionResult {
        return when (val config = ConfigStore.getActionConfig(context)) {
            is ActionConfig.OpenApp -> openApp(context, config)
            is ActionConfig.OpenUrl -> openUrl(context, config)
            is ActionConfig.SetAlarm -> setAlarm(context, config)
            ActionConfig.MediaPlayPause -> mediaPlayPause(context)
            ActionConfig.None -> ActionExecutionResult(
                actionLabel = "No action configured",
                success = false,
                errorMessage = "No action configured",
            )
        }
    }

    private fun openApp(context: Context, config: ActionConfig.OpenApp): ActionExecutionResult {
        val label = "Opened ${config.packageName}"
        val launchIntent = context.packageManager.getLaunchIntentForPackage(config.packageName)
            ?: return ActionExecutionResult(
                actionLabel = label,
                success = false,
                errorMessage = "Package not installed: ${config.packageName}",
            )
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return launch(context, launchIntent, label)
    }

    private fun openUrl(context: Context, config: ActionConfig.OpenUrl): ActionExecutionResult {
        val label = "Opened ${config.url}"
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(config.url))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return launch(context, intent, label)
    }

    private fun setAlarm(context: Context, config: ActionConfig.SetAlarm): ActionExecutionResult {
        val label = "Alarm set for %02d:%02d".format(config.hour, config.minute)
        val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
            putExtra(AlarmClock.EXTRA_HOUR, config.hour)
            putExtra(AlarmClock.EXTRA_MINUTES, config.minute)
            if (!config.label.isNullOrBlank()) putExtra(AlarmClock.EXTRA_MESSAGE, config.label)
            if (config.daysOfWeek.isNotEmpty()) {
                putExtra(AlarmClock.EXTRA_DAYS, ArrayList(config.daysOfWeek))
            }
            // Hint to the receiving clock app to skip its confirmation UI and set the alarm
            // directly. Not OS-enforced — support is up to the clock app. Confirmed on-device
            // (Oppo Find X9, ColorOS 16, com.coloros.alarmclock) that it's honored: the alarm is
            // created silently with no Clock app UI appearing in the foreground.
            putExtra(AlarmClock.EXTRA_SKIP_UI, true)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return launch(context, intent, label)
    }

    // Purely a background system-state change (no Activity involved), so it never needs the
    // BAL-exempt launch()/notification-fallback dance that OpenApp/OpenUrl/SetAlarm go through.
    private fun mediaPlayPause(context: Context): ActionExecutionResult {
        val label = "Play/Pause media"
        return try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val eventTime = SystemClock.uptimeMillis()
            audioManager.dispatchMediaKeyEvent(
                KeyEvent(eventTime, eventTime, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, 0)
            )
            audioManager.dispatchMediaKeyEvent(
                KeyEvent(eventTime, eventTime, KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, 0)
            )
            ActionExecutionResult(actionLabel = label, success = true)
        } catch (e: Exception) {
            ActionExecutionResult(actionLabel = label, success = false, errorMessage = e.message)
        }
    }

    private fun launch(
        context: Context,
        targetIntent: Intent,
        label: String,
    ): ActionExecutionResult {
        if (Settings.canDrawOverlays(context)) {
            // BAL exemption applies — launch directly, no notification.
            return try {
                context.startActivity(targetIntent)
                ActionExecutionResult(actionLabel = label, success = true)
            } catch (e: Exception) {
                ActionExecutionResult(actionLabel = label, success = false, errorMessage = e.message)
            }
        }
        return launchViaNotification(context, targetIntent, label)
    }

    private fun launchViaNotification(
        context: Context,
        targetIntent: Intent,
        label: String,
    ): ActionExecutionResult {
        return try {
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            ensureChannel(notificationManager)

            val pendingIntent = PendingIntent.getActivity(
                context,
                TRIGGER_NOTIFICATION_ID,
                targetIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val notification = Notification.Builder(context, TRIGGER_CHANNEL_ID)
                .setContentTitle("SnapKey Mapper")
                .setContentText(label)
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setContentIntent(pendingIntent)
                .setFullScreenIntent(pendingIntent, true)
                .setAutoCancel(true)
                .build()

            notificationManager?.notify(TRIGGER_NOTIFICATION_ID, notification)
            ActionExecutionResult(actionLabel = label, success = true)
        } catch (e: Exception) {
            ActionExecutionResult(actionLabel = label, success = false, errorMessage = e.message)
        }
    }

    private fun ensureChannel(notificationManager: NotificationManager?) {
        val channel = NotificationChannel(
            TRIGGER_CHANNEL_ID,
            "SnapKey Mapper — triggered actions",
            NotificationManager.IMPORTANCE_HIGH,
        )
        notificationManager?.createNotificationChannel(channel)
    }
}
