package io.dupuis.bigface

import android.Manifest
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.View
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.NavigatorConfiguration
import dev.hotwire.navigation.util.applyDefaultImeWindowInsets

class MainActivity : HotwireActivity() {
    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { }

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        findViewById<View>(R.id.main_nav_host).applyDefaultImeWindowInsets()

        intent?.getStringExtra("call_id")?.let {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        requestPermissionsIfNeeded()
    }

    private fun requestPermissionsIfNeeded() {
        val permissions = arrayOf(
            Manifest.permission.CAMERA,
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.POST_NOTIFICATIONS
        )
        val needed = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (needed.isNotEmpty()) {
            permissionLauncher.launch(needed.toTypedArray())
        }
    }

    override fun navigatorConfigurations() = listOf(
        NavigatorConfiguration(
            name = "main",
            startLocation = getStartLocation(),
            navigatorHostId = R.id.main_nav_host
        )
    )

    private fun getStartLocation(): String {
        val callId = intent.getStringExtra("call_id") ?: return BuildConfig.SERVER_URL
        val callerName = intent.getStringExtra("caller_name") ?: return BuildConfig.SERVER_URL
        val autoAnswer = intent.getBooleanExtra("auto_answer", false)

        cancelCallNotification(callId)

        val baseUrl = "${BuildConfig.SERVER_URL}?incoming_call_id=$callId&caller_name=${java.net.URLEncoder.encode(callerName, "UTF-8")}"
        return if (autoAnswer) "$baseUrl&auto_answer=true" else baseUrl
    }

    private fun cancelCallNotification(callId: String) {
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.cancel(callId.hashCode())
    }
}
