package com.sgm.snapkeymapper

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Dynamically registered (not manifest — ACTION_INTERRUPTION_FILTER_CHANGED is a protected
 * broadcast that can't be manifest-declared) inside SnapKeyListenerService. Fires the configured
 * action when DND transitions from off to on; DND itself is left as-is afterward.
 */
class DndInterruptionReceiver(
    private val onGenuineDndTrigger: () -> Unit,
) : BroadcastReceiver() {

    private var wasAll = true

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != NotificationManager.ACTION_INTERRUPTION_FILTER_CHANGED) return
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        val isAll = notificationManager.currentInterruptionFilter ==
            NotificationManager.INTERRUPTION_FILTER_ALL
        val turnedOn = wasAll && !isAll
        wasAll = isAll
        if (turnedOn) onGenuineDndTrigger()
    }
}
