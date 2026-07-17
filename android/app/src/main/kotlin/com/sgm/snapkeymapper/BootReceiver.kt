package com.sgm.snapkeymapper

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Manifest-registered — `BOOT_COMPLETED` is one of the few implicit broadcasts still allowed to be
 * declared statically (unlike `ACTION_INTERRUPTION_FILTER_CHANGED`, see `DndInterruptionReceiver`).
 * Restarts the foreground service after a full reboot if the user had mapping enabled:
 * `START_STICKY` only survives the OS killing the process, not a reboot, and `MainActivity`'s launch
 * -time reconciliation doesn't help either since the user may not reopen the app after rebooting.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        if (ConfigStore.getServiceShouldRun(context)) {
            SnapKeyListenerService.start(context)
        }
    }
}
