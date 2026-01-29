package io.dupuis.bigface

import android.util.Log
import android.webkit.CookieManager
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

// Handles Firebase Cloud Messaging push notifications.
// Delegates notification display to CallNotificationManager.
class BigfaceMessagingService : FirebaseMessagingService() {
    companion object {
        private const val TAG = "BigfaceMessaging"

        fun configurePushToken() {
            if (!isFirebaseConfigured()) return

            FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    val token = task.result
                    Log.d(TAG, "FCM Token: $token")
                    setPushTokenCookie(token)
                }
            }
        }

        private fun setPushTokenCookie(token: String) {
            val cookieManager = CookieManager.getInstance()
            cookieManager.setCookie(BuildConfig.SERVER_URL, "push_token=$token; Path=/")
        }

        private fun isFirebaseConfigured(): Boolean {
            return try {
                FirebaseApp.getInstance()
                true
            } catch (e: IllegalStateException) {
                false
            }
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "FCM Token refreshed: $token")
        setPushTokenCookie(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        Log.d(TAG, "Message received: ${message.data}")

        val type = message.data["type"]
        if (type == "incoming_call") {
            val callId = message.data["call_id"] ?: return
            val callerName = message.data["caller_name"] ?: "Unknown"

            CallNotificationManager.showIncomingCall(this, callId, callerName)
        }
    }
}
