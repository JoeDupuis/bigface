package io.dupuis.bigface

import android.os.Bundle
import android.view.View
import android.webkit.PermissionRequest
import dev.hotwire.core.turbo.webview.HotwireWebChromeClient
import dev.hotwire.navigation.destinations.HotwireDestinationDeepLink
import dev.hotwire.navigation.fragments.HotwireWebFragment

@HotwireDestinationDeepLink(uri = "hotwire://fragment/call")
class CallFragment : HotwireWebFragment() {
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        toolbarForNavigation()?.visibility = View.GONE
        setupWebViewForWebRTC()
    }

    private fun setupWebViewForWebRTC() {
        navigator.session.webView.apply {
            settings.mediaPlaybackRequiresUserGesture = false
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
        }
    }

    override fun createWebChromeClient(): HotwireWebChromeClient {
        return object : HotwireWebChromeClient(navigator.session) {
            override fun onPermissionRequest(request: PermissionRequest) {
                activity?.runOnUiThread {
                    request.grant(request.resources)
                }
            }
        }
    }
}
