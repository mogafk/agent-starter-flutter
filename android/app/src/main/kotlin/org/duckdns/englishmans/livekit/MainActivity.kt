package org.duckdns.englishmans.livekit

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST = 1
    }

    // Title of the running call service, or null when no call is active.
    private var activeCallTitle: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "englishmans/call_service")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val title = call.argument<String>("title") ?: "Ongoing call"
                        activeCallTitle = title
                        CallService.start(this, title)
                        requestNotificationPermission()
                        result.success(null)
                    }
                    "stop" -> {
                        activeCallTitle = null
                        CallService.stop(this)
                        result.success(null)
                    }
                    "moveToBackground" -> {
                        moveTaskToBack(true)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Without it (Android 13+) the service still runs, but its notification is hidden.
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_PERMISSION_REQUEST)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        // The service's notification was dropped while the permission was missing; post it again.
        val title = activeCallTitle
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST &&
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED &&
            title != null
        ) {
            CallService.start(this, title)
        }
    }

    override fun onDestroy() {
        // The call can't outlive the activity's Flutter engine, so don't leave a stale notification.
        if (isFinishing) CallService.stop(this)
        super.onDestroy()
    }
}
