package io.dupuis.bigface

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

// Debug receiver for triggering notifications via ADB in debug builds.
// Usage: adb shell am broadcast -a io.dupuis.bigface.DEBUG_INCOMING_CALL \
//        -n <package>/io.dupuis.bigface.DebugMessagingReceiver \
//        --es call_id "123" --es caller_name "Test User"
class DebugMessagingReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val callId = intent.getStringExtra("call_id") ?: return
        val callerName = intent.getStringExtra("caller_name") ?: "Unknown"
        CallNotificationManager.showIncomingCall(context, callId, callerName)
    }
}
