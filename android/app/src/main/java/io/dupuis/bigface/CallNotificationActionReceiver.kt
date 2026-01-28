package io.dupuis.bigface

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.webkit.CookieManager
import java.net.HttpURLConnection
import java.net.URL

class CallNotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val callId = intent.getStringExtra("call_id") ?: return
        val notificationManager = context.getSystemService(NotificationManager::class.java)
        notificationManager.cancel(callId.hashCode())

        if (intent.action == "ACTION_DECLINE") {
            declineCall(callId)
        }
    }

    private fun declineCall(callId: String) {
        Thread {
            try {
                val cookies = CookieManager.getInstance().getCookie(BuildConfig.SERVER_URL)
                    ?: return@Thread
                val url = URL("${BuildConfig.SERVER_URL}calls/$callId/decline")
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Cookie", cookies)
                connection.instanceFollowRedirects = false
                connection.doOutput = true
                connection.connect()
                connection.responseCode
                connection.disconnect()
            } catch (e: Exception) {
            }
        }.start()
    }
}
