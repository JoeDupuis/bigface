package io.dupuis.bigface

import android.app.Application
import dev.hotwire.core.bridge.BridgeComponentFactory
import dev.hotwire.core.config.Hotwire
import dev.hotwire.core.turbo.config.PathConfiguration
import dev.hotwire.navigation.config.registerBridgeComponents
import dev.hotwire.navigation.config.registerFragmentDestinations
import dev.hotwire.navigation.fragments.HotwireWebFragment

class BigfaceApplication : Application() {
    companion object {
        var hasWindowFocus = false
    }

    override fun onCreate() {
        super.onCreate()
        configureApp()
        CallNotificationManager.createNotificationChannel(this)
        BigfaceMessagingService.configurePushToken()
    }

    private fun configureApp() {
        Hotwire.config.debugLoggingEnabled = BuildConfig.DEBUG
        Hotwire.config.webViewDebuggingEnabled = BuildConfig.DEBUG

        Hotwire.registerBridgeComponents(
            BridgeComponentFactory("call", ::CallBridgeComponent)
        )

        Hotwire.registerFragmentDestinations(
            HotwireWebFragment::class,
            CallFragment::class
        )

        Hotwire.loadPathConfiguration(
            context = this,
            location = PathConfiguration.Location(
                assetFilePath = "json/path-configuration.json",
                remoteFileUrl = "${BuildConfig.SERVER_URL}/configurations/android_v1"
            )
        )
    }

}
