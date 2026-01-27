package io.dupuis.bigface

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import android.webkit.CookieManager
import androidx.core.app.NotificationCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class BigfaceMessagingService : FirebaseMessagingService() {
    companion object {
        private const val TAG = "BigfaceMessaging"
        private const val CHANNEL_ID = "calls"

        fun createNotificationChannel(context: Context) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Incoming Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for incoming calls"
            }

            val notificationManager = context.getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }

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
            showIncomingCallNotification(callId, callerName)
        }
    }

    private fun showIncomingCallNotification(callId: String, callerName: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("call_id", callId)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val answerIntent = Intent(this, CallNotificationActionReceiver::class.java).apply {
            action = "ACTION_ANSWER"
            putExtra("call_id", callId)
        }
        val answerPendingIntent = PendingIntent.getBroadcast(
            this,
            callId.hashCode(),
            answerIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val declineIntent = Intent(this, CallNotificationActionReceiver::class.java).apply {
            action = "ACTION_DECLINE"
            putExtra("call_id", callId)
        }
        val declinePendingIntent = PendingIntent.getBroadcast(
            this,
            callId.hashCode() + 1,
            declineIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Incoming Call")
            .setContentText("$callerName is calling")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .addAction(R.drawable.ic_notification, "Answer", answerPendingIntent)
            .addAction(R.drawable.ic_notification, "Decline", declinePendingIntent)
            .build()

        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(callId.hashCode(), notification)
    }
}
