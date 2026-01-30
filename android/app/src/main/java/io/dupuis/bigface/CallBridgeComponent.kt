package io.dupuis.bigface

import android.util.Log
import dev.hotwire.core.bridge.BridgeComponent
import dev.hotwire.core.bridge.BridgeDelegate
import dev.hotwire.core.bridge.Message
import dev.hotwire.navigation.destinations.HotwireDestination

class CallBridgeComponent(
    name: String,
    private val delegate: BridgeDelegate<HotwireDestination>
) : BridgeComponent<HotwireDestination>(name, delegate) {

    override fun onReceive(message: Message) {
        Log.d("CallBridgeComponent", "onReceive: ${message.event}")
        when (message.event) {
            "close" -> {
                Log.d("CallBridgeComponent", "Closing activity")
                delegate.destination.fragment.activity?.finish()
            }
            "ring" -> {
                Log.d("CallBridgeComponent", "Starting ringtone")
                delegate.destination.fragment.context?.let { RingtonePlayer.start(it) }
            }
            "stopRing" -> {
                Log.d("CallBridgeComponent", "Stopping ringtone")
                RingtonePlayer.stop()
            }
        }
    }
}
