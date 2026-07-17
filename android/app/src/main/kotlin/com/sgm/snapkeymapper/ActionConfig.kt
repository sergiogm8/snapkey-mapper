package com.sgm.snapkeymapper

import org.json.JSONArray
import org.json.JSONObject

/** ToggleTorch was deliberately dropped from scope, see CLAUDE.md. */
sealed class ActionConfig {
    data class OpenApp(val packageName: String) : ActionConfig()
    data class OpenUrl(val url: String) : ActionConfig()

    /** [daysOfWeek] uses java.util.Calendar day-of-week constants (1=Sunday..7=Saturday), matching
     *  what AlarmClock.EXTRA_DAYS expects — empty means a one-time alarm. */
    data class SetAlarm(
        val hour: Int,
        val minute: Int,
        val label: String? = null,
        val daysOfWeek: List<Int> = emptyList(),
    ) : ActionConfig()
    object MediaPlayPause : ActionConfig()
    object None : ActionConfig()

    fun toJson(): String {
        val json = JSONObject()
        when (this) {
            is OpenApp -> {
                json.put("type", TYPE_OPEN_APP)
                json.put("packageName", packageName)
            }
            is OpenUrl -> {
                json.put("type", TYPE_OPEN_URL)
                json.put("url", url)
            }
            is SetAlarm -> {
                json.put("type", TYPE_SET_ALARM)
                json.put("hour", hour)
                json.put("minute", minute)
                if (label != null) json.put("label", label)
                json.put("daysOfWeek", JSONArray(daysOfWeek))
            }
            MediaPlayPause -> json.put("type", TYPE_MEDIA_PLAY_PAUSE)
            None -> json.put("type", TYPE_NONE)
        }
        return json.toString()
    }

    companion object {
        private const val TYPE_OPEN_APP = "open_app"
        private const val TYPE_OPEN_URL = "open_url"
        private const val TYPE_SET_ALARM = "set_alarm"
        private const val TYPE_MEDIA_PLAY_PAUSE = "media_play_pause"
        private const val TYPE_NONE = "none"

        fun fromJson(json: String?): ActionConfig {
            if (json.isNullOrBlank()) return None
            return try {
                val obj = JSONObject(json)
                when (obj.optString("type")) {
                    TYPE_OPEN_APP -> OpenApp(obj.getString("packageName"))
                    TYPE_OPEN_URL -> OpenUrl(obj.getString("url"))
                    TYPE_SET_ALARM -> SetAlarm(
                        hour = obj.getInt("hour"),
                        minute = obj.getInt("minute"),
                        label = if (obj.has("label")) obj.optString("label") else null,
                        daysOfWeek = obj.optJSONArray("daysOfWeek")?.let { arr ->
                            (0 until arr.length()).map { arr.getInt(it) }
                        } ?: emptyList(),
                    )
                    TYPE_MEDIA_PLAY_PAUSE -> MediaPlayPause
                    else -> None
                }
            } catch (e: Exception) {
                None
            }
        }
    }
}
