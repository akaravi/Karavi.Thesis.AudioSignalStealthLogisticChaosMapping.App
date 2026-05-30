package ca.karavi.audiowmark.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class WidgetCaptureActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWidgetCaptureLaunch" -> {
                    val action =
                        intent.getStringExtra(QuickActionsWidgetProvider.EXTRA_WIDGET_ACTION)
                            ?: QuickActionsWidgetProvider.ACTION_RECORD
                    result.success(
                        mapOf(
                            "active" to true,
                            "action" to action,
                        ),
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    companion object {
        private const val channelName = "ca.karavi.audiowmark.app/widget_capture"
    }
}
