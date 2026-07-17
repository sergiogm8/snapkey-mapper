package com.sgm.snapkeymapper

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Capped ring buffer of fired actions (manual test or real DND trigger), newest first. */
object TriggerLogStore {
    private const val KEY_LOG = "trigger_log"
    private const val MAX_ENTRIES = 50

    fun append(context: Context, result: ActionExecutionResult) {
        val prefs = ConfigStore.prefs(context)
        val current = JSONArray(prefs.getString(KEY_LOG, "[]"))
        val entry = JSONObject().apply {
            put("timestamp", System.currentTimeMillis())
            put("actionLabel", result.actionLabel)
            put("success", result.success)
            put("errorMessage", result.errorMessage)
        }
        val updated = JSONArray()
        updated.put(entry)
        for (i in 0 until current.length()) {
            if (updated.length() >= MAX_ENTRIES) break
            updated.put(current.get(i))
        }
        prefs.edit().putString(KEY_LOG, updated.toString()).apply()
    }

    fun getAllAsList(context: Context): List<Map<String, Any?>> {
        val prefs = ConfigStore.prefs(context)
        val array = JSONArray(prefs.getString(KEY_LOG, "[]"))
        return (0 until array.length()).map { i ->
            val obj = array.getJSONObject(i)
            mapOf(
                "timestamp" to obj.optLong("timestamp"),
                "actionLabel" to obj.optString("actionLabel"),
                "success" to obj.optBoolean("success"),
                "errorMessage" to if (obj.isNull("errorMessage")) null else obj.optString("errorMessage"),
            )
        }
    }
}
