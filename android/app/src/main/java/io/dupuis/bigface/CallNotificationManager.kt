package io.dupuis.bigface

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.Person
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ProcessLifecycleOwner

object CallNotificationManager {
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

    fun showIncomingCall(context: Context, callId: String, callerName: String) {
        val isInForeground = ProcessLifecycleOwner.get().lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)
        if (isInForeground) return
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("call_id", callId)
            putExtra("caller_name", callerName)
        }

        val contentIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val answerIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("call_id", callId)
            putExtra("caller_name", callerName)
            putExtra("auto_answer", true)
        }
        val answerPendingIntent = PendingIntent.getActivity(
            context,
            callId.hashCode(),
            answerIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val declineIntent = Intent(context, CallNotificationActionReceiver::class.java).apply {
            action = "ACTION_DECLINE"
            putExtra("call_id", callId)
        }
        val declinePendingIntent = PendingIntent.getBroadcast(
            context,
            callId.hashCode() + 1,
            declineIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val caller = Person.Builder()
            .setName(callerName)
            .setImportant(true)
            .build()

        val callStyle = NotificationCompat.CallStyle.forIncomingCall(
            caller,
            declinePendingIntent,
            answerPendingIntent
        )

        val fullScreenIntent = PendingIntent.getActivity(
            context,
            callId.hashCode() + 2,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(contentIntent)
            .setFullScreenIntent(fullScreenIntent, true)
            .setStyle(callStyle)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setOngoing(true)
            .build()

        val notificationManager = context.getSystemService(NotificationManager::class.java)
        notificationManager.notify(callId.hashCode(), notification)
    }
}
