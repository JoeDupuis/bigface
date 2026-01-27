package io.dupuis.bigface

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class CallNotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val callId = intent.getStringExtra("call_id") ?: return
        val notificationManager = context.getSystemService(NotificationManager::class.java)
        notificationManager.cancel(callId.hashCode())
    }
}
