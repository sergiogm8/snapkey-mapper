package com.sgm.snapkeymapper

import android.content.Context
import android.content.SharedPreferences

/**
 * Own SharedPreferences file, written directly from Kotlin — deliberately NOT the file Flutter's
 * `shared_preferences` plugin uses (that plugin prefixes every key with "flutter."). Config is
 * written straight from Dart via MethodChannel and read fresh by the service on every fire, so
 * there's exactly one writer and no prefix mismatch to keep in sync.
 */
object ConfigStore {
    const val PREFS_NAME = "snapkey_prefs"
    private const val KEY_ACTION_CONFIG = "action_config"
    private const val KEY_SERVICE_SHOULD_RUN = "service_should_run"

    fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun setActionConfigJson(context: Context, json: String) {
        prefs(context).edit().putString(KEY_ACTION_CONFIG, json).apply()
    }

    fun getActionConfigJson(context: Context): String? =
        prefs(context).getString(KEY_ACTION_CONFIG, null)

    fun getActionConfig(context: Context): ActionConfig =
        ActionConfig.fromJson(getActionConfigJson(context))

    fun setServiceShouldRun(context: Context, shouldRun: Boolean) {
        prefs(context).edit().putBoolean(KEY_SERVICE_SHOULD_RUN, shouldRun).apply()
    }

    fun getServiceShouldRun(context: Context): Boolean =
        prefs(context).getBoolean(KEY_SERVICE_SHOULD_RUN, false)
}
