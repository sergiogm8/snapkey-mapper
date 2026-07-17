package com.sgm.snapkeymapper

import android.Manifest
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestPostNotificationsPermissionIfNeeded()
        reconcileServiceState()
        applySystemBarAppearance()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        applySystemBarAppearance()
    }

    // Flutter's engine can reassert its own system-bar appearance after onCreate() returns
    // (first-frame attach) — reapplying in onResume() keeps this app's appearance as the last word.
    override fun onResume() {
        super.onResume()
        applySystemBarAppearance()
    }

    /**
     * Sets status/nav bar icon appearance directly via WindowInsetsControllerCompat rather than
     * Flutter's Dart-side SystemUiOverlayStyle bridge, which proved unreliable on this device.
     * Android 16 makes edge-to-edge mandatory with no opt-out for this app's targetSdk, so bar
     * *color* APIs are no-ops here — embrace edge-to-edge and disable the OS's automatic contrast
     * scrim instead, since the app already guarantees contrast via icon appearance. Reacts to
     * system dark/light changes.
     */
    private fun applySystemBarAppearance() {
        val isNightMode = (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES

        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            @Suppress("DEPRECATION")
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }

        val insetsController = WindowInsetsControllerCompat(window, window.decorView)
        insetsController.isAppearanceLightStatusBars = !isNightMode
        insetsController.isAppearanceLightNavigationBars = !isNightMode
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val handler = SnapKeyMethodChannelHandler(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONFIG_CHANNEL)
            .setMethodCallHandler(handler.configHandler)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL)
            .setMethodCallHandler(handler.serviceHandler)
    }

    // Android 13+ makes this a runtime permission — the manifest declaration alone doesn't make the
    // foreground-service notification visible. Requested unconditionally on launch.
    private fun requestPostNotificationsPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), POST_NOTIFICATIONS_REQUEST_CODE)
        }
    }

    // Reasserts the "mapping enabled" state on every launch — without this, a persisted
    // "should run" flag can show ON in the UI while the Service isn't actually running.
    private fun reconcileServiceState() {
        if (ConfigStore.getServiceShouldRun(applicationContext)) {
            SnapKeyListenerService.start(applicationContext)
        }
    }

    companion object {
        const val CONFIG_CHANNEL = "snapkey_mapper/config"
        const val SERVICE_CHANNEL = "snapkey_mapper/service"
        private const val POST_NOTIFICATIONS_REQUEST_CODE = 4201
    }
}
