package com.sgm.snapkeymapper

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.os.Build
import android.os.IBinder

/**
 * Persistent foreground service — the self-sufficient runtime this whole app is built around.
 * Flutter is only a control panel; this service keeps working whether or not the Flutter engine is
 * running. See CLAUDE.md for the rationale (native Kotlin service over a Dart headless isolate, to
 * survive ColorOS's background-process management).
 */
class SnapKeyListenerService : Service() {

    private var dndReceiver: DndInterruptionReceiver? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        startForegroundCompat()
        registerDndReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            ConfigStore.setServiceShouldRun(applicationContext, false)
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        // ColorOS can kill the process when the app is swiped from recents; relaunch defensively.
        val restartIntent = Intent(applicationContext, SnapKeyListenerService::class.java)
        applicationContext.startForegroundService(restartIntent)
    }

    override fun onDestroy() {
        isRunning = false
        dndReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: IllegalArgumentException) {
                // Already unregistered — fine.
            }
        }
        dndReceiver = null
        super.onDestroy()
    }

    private fun registerDndReceiver() {
        val receiver = DndInterruptionReceiver { handleGenuineTrigger() }
        val filter = IntentFilter(NotificationManager.ACTION_INTERRUPTION_FILTER_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }
        dndReceiver = receiver
    }

    private fun handleGenuineTrigger() {
        val result = ActionExecutor.execute(applicationContext)
        TriggerLogStore.append(applicationContext, result)
    }

    /**
     * The manifest's `android:foregroundServiceType="specialUse"` alone is not enough on API 34+ —
     * the type must also be passed to startForeground() itself, or the system logs "Foreground
     * service start ... does not have any types" and treats the service with less protection than
     * a properly-typed specialUse service gets. Guarded by SDK check since the type constant and
     * 3-arg overload only exist from API 34 (UPSIDE_DOWN_CAKE); minSdk is 26.
     */
    private fun startForegroundCompat() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(): Notification {
        val notificationManager = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "SnapKey Mapper",
            NotificationManager.IMPORTANCE_LOW,
        )
        notificationManager?.createNotificationChannel(channel)

        val stopIntent = Intent(this, SnapKeyListenerService::class.java).setAction(ACTION_STOP)
        val stopPendingIntent = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val stopAction = Notification.Action.Builder(
            Icon.createWithResource(this, android.R.drawable.ic_lock_power_off),
            "Turn off",
            stopPendingIntent,
        ).build()

        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("SnapKey Mapper")
            .setContentText("Active")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .addAction(stopAction)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "snapkey_mapper_service"
        private const val NOTIFICATION_ID = 1001
        private const val ACTION_STOP = "com.sgm.snapkeymapper.action.STOP_SERVICE"

        /**
         * True while this process has a live instance of the service (set in onCreate, cleared in
         * onDestroy). Lets the UI show the actual live state instead of just the persisted
         * "should run" intent — the two can legitimately disagree right after a fresh install or
         * process death, before MainActivity's reconciliation call catches up.
         */
        @Volatile
        var isRunning: Boolean = false
            private set

        fun start(context: Context) {
            val intent = Intent(context, SnapKeyListenerService::class.java)
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, SnapKeyListenerService::class.java))
        }
    }
}
