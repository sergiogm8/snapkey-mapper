package com.sgm.snapkeymapper

import android.Manifest
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

/**
 * Implements the actual method dispatch for both channels, kept separate from MainActivity so it's
 * readable/testable in isolation. `snapkey_mapper/config` handles just the action config;
 * `snapkey_mapper/service` handles everything else (service lifecycle, manual test trigger, trigger
 * log, notification-policy permission).
 */
class SnapKeyMethodChannelHandler(private val appContext: Context) {

    // `getInstalledApps`/`getAppIcon` do real PackageManager work off the platform thread (shared
    // with Flutter's UI), posting results back via [mainHandler] as MethodChannel.Result requires.
    private val backgroundExecutor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

    // In-memory icon cache, keyed by packageName — invalidated on process death.
    private val iconCache = ConcurrentHashMap<String, ByteArray>()

    val configHandler = MethodChannel.MethodCallHandler { call, result ->
        when (call.method) {
            "setActionConfig" -> {
                val json = call.argument<String>("json")
                if (json == null) {
                    result.error("invalid_argument", "json is required", null)
                } else {
                    ConfigStore.setActionConfigJson(appContext, json)
                    result.success(null)
                }
            }
            "getActionConfig" -> result.success(ConfigStore.getActionConfigJson(appContext))
            else -> result.notImplemented()
        }
    }

    val serviceHandler = MethodChannel.MethodCallHandler { call, result ->
        when (call.method) {
            "start" -> {
                ConfigStore.setServiceShouldRun(appContext, true)
                SnapKeyListenerService.start(appContext)
                result.success(null)
            }
            "stop" -> {
                ConfigStore.setServiceShouldRun(appContext, false)
                SnapKeyListenerService.stop(appContext)
                result.success(null)
            }
            "isServiceShouldRun" -> result.success(ConfigStore.getServiceShouldRun(appContext))
            "isServiceRunning" -> result.success(SnapKeyListenerService.isRunning)
            "isPostNotificationsGranted" -> {
                val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    appContext.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                        PackageManager.PERMISSION_GRANTED
                } else {
                    true // Runtime grant didn't exist before API 33 — notifications just worked.
                }
                result.success(granted)
            }
            "testTrigger" -> {
                val execResult = ActionExecutor.execute(appContext)
                TriggerLogStore.append(appContext, execResult)
                result.success(
                    mapOf(
                        "actionLabel" to execResult.actionLabel,
                        "success" to execResult.success,
                        "errorMessage" to execResult.errorMessage,
                    ),
                )
            }
            "getTriggerLog" -> result.success(TriggerLogStore.getAllAsList(appContext))
            "isNotificationPolicyGranted" -> {
                val notificationManager =
                    appContext.getSystemService(NotificationManager::class.java)
                result.success(notificationManager?.isNotificationPolicyAccessGranted == true)
            }
            "openNotificationPolicySettings" -> {
                val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                appContext.startActivity(intent)
                result.success(null)
            }
            "isFullScreenIntentGranted" -> {
                val notificationManager =
                    appContext.getSystemService(NotificationManager::class.java)
                val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    notificationManager?.canUseFullScreenIntent() == true
                } else {
                    true // Gate didn't exist before API 34 — the manifest permission was enough.
                }
                result.success(granted)
            }
            "openFullScreenIntentSettings" -> {
                val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT)
                        .setData(Uri.parse("package:${appContext.packageName}"))
                } else {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        .setData(Uri.parse("package:${appContext.packageName}"))
                }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                appContext.startActivity(intent)
                result.success(null)
            }
            "isOverlayGranted" -> result.success(Settings.canDrawOverlays(appContext))
            "openOverlaySettings" -> {
                // "Display over other apps" special access — holding it exempts the app from
                // Background Activity Launch restrictions, letting ActionExecutor start the
                // configured action directly instead of via a notification.
                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                    .setData(Uri.parse("package:${appContext.packageName}"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                appContext.startActivity(intent)
                result.success(null)
            }
            "openAppSettings" -> {
                // Generic fallback fix action — e.g. for POST_NOTIFICATIONS once the user has denied
                // the runtime prompt once, re-requesting it may silently no-op, so routing to the
                // app's own system settings page (where they can flip the toggle by hand) is the
                // reliable recourse.
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    .setData(Uri.parse("package:${appContext.packageName}"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                appContext.startActivity(intent)
                result.success(null)
            }
            "isBatteryOptimizationIgnored" -> {
                val powerManager = appContext.getSystemService(PowerManager::class.java)
                result.success(powerManager?.isIgnoringBatteryOptimizations(appContext.packageName) == true)
            }
            "requestBatteryOptimizationExemption" -> {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    .setData(Uri.parse("package:${appContext.packageName}"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                try {
                    appContext.startActivity(intent)
                } catch (e: ActivityNotFoundException) {
                    // Some OEM builds disallow this specific intent action outright — fall back to
                    // the generic app settings page where the user can find battery settings by hand.
                    appContext.startActivity(
                        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                            .setData(Uri.parse("package:${appContext.packageName}"))
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                }
                result.success(null)
            }
            "openAutostartSettings" -> {
                // Best-effort: ColorOS's autostart/"startup manager" screen has no stable public
                // API and has moved package+class across ColorOS versions. Verified on-device
                // (real Find X9, ColorOS 16 / CPH2797_16.0.8.301):
                //  - The old com.coloros.safecenter candidates don't exist at all on ColorOS 16
                //    (that package isn't installed; it's now com.oplus.safecenter, which doesn't
                //    have a startup-manager screen).
                //  - The current location is com.oplus.battery's StartupAppListActivity — but it
                //    requires the signature-level `oplus.permission.OPLUS_COMPONENT_SAFE`
                //    permission and throws SecurityException (not ActivityNotFoundException) for
                //    any third-party caller, confirmed via adb. It's listed anyway in case a
                //    different build/region relaxes that.
                //  - The app's own details page (previously the fallback here) has NO autostart
                //    toggle on ColorOS 16 either (confirmed by inspection) — so the fallback now
                //    goes to the Settings home screen instead, where the user can search
                //    "Startup"/"Auto-launch" themselves.
                val candidates = listOf(
                    ComponentName(
                        "com.coloros.safecenter",
                        "com.coloros.safecenter.permission.startup.StartupAppListActivity",
                    ),
                    ComponentName(
                        "com.coloros.safecenter",
                        "com.coloros.safecenter.startupapp.StartupAppListActivity",
                    ),
                    ComponentName(
                        "com.oplus.battery",
                        "com.oplus.startupapp.view.StartupAppListActivity",
                    ),
                )
                var opened = false
                for (component in candidates) {
                    try {
                        appContext.startActivity(
                            Intent().setComponent(component).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        opened = true
                        break
                    } catch (e: ActivityNotFoundException) {
                        // Try the next candidate.
                    } catch (e: SecurityException) {
                        // Signature-protected on this build — try the next candidate.
                    }
                }
                if (!opened) {
                    appContext.startActivity(
                        Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                }
                result.success(opened)
            }
            "openSystemSettings" -> {
                // Generic Settings home screen — there's no documented, verified deep link to
                // ColorOS's Snap Key assignment screen itself (unlike openAutostartSettings above,
                // which has real candidate component names); the user navigates/searches from here.
                val intent = Intent(Settings.ACTION_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                appContext.startActivity(intent)
                result.success(null)
            }
            "getInstalledApps" -> {
                backgroundExecutor.execute {
                    val pm = appContext.packageManager
                    val launcherIntent =
                        Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                    val apps = pm.queryIntentActivities(launcherIntent, 0)
                        .distinctBy { it.activityInfo.packageName }
                        .filter { it.activityInfo.packageName != appContext.packageName }
                        .map { info ->
                            mapOf(
                                "packageName" to info.activityInfo.packageName,
                                "label" to info.loadLabel(pm).toString(),
                            )
                        }
                        .sortedBy { (it["label"] as String).lowercase() }
                    mainHandler.post { result.success(apps) }
                }
            }
            "getAppIcon" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName == null) {
                    result.error("invalid_argument", "packageName is required", null)
                } else {
                    val cached = iconCache[packageName]
                    if (cached != null) {
                        result.success(cached)
                    } else {
                        backgroundExecutor.execute {
                            val bytes = loadAppIconBytes(packageName)
                            if (bytes != null) {
                                iconCache[packageName] = bytes
                            }
                            mainHandler.post { result.success(bytes) }
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Loads a single app's launcher icon, rasterizes it to a fixed-size bitmap, and PNG-encodes
     * it. Runs off the platform thread (see [backgroundExecutor]). Returns null (rather than
     * throwing) if the package is gone — e.g. uninstalled between list load and icon fetch — so
     * the caller can fall back to the letter-avatar instead of surfacing an error.
     */
    private fun loadAppIconBytes(packageName: String): ByteArray? {
        return try {
            val drawable = appContext.packageManager.getApplicationIcon(packageName)
            val bitmap = Bitmap.createBitmap(
                APP_ICON_SIZE_PX,
                APP_ICON_SIZE_PX,
                Bitmap.Config.ARGB_8888,
            )
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            ByteArrayOutputStream().use { stream ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                stream.toByteArray()
            }
        } catch (e: PackageManager.NameNotFoundException) {
            null
        } catch (e: Exception) {
            null
        }
    }

    private companion object {
        // Fixed rasterize size — keeps the PNG payload small regardless of how large the source
        // launcher icon asset is (adaptive icons in particular can be much bigger).
        const val APP_ICON_SIZE_PX = 128
    }
}
