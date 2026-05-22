package ir.ntk.audiowmark.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val methodChannelName = "ir.ntk.audiowmark.app/open_file"
    private val eventChannelName = "ir.ntk.audiowmark.app/open_file_events"

    private var eventSink: EventChannel.EventSink? = null
    private var initialOpenPayload: Map<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            methodChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialOpenPayload" -> result.success(initialOpenPayload)
                else -> result.notImplemented()
            }
        }
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            eventChannelName,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            },
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        captureViewIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureViewIntent(intent)
    }

    private fun captureViewIntent(intent: Intent?) {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return
        val uri = intent.data ?: return
        val payload = resolveOpenPayload(uri) ?: return
        initialOpenPayload = payload
        eventSink?.success(payload)
    }

    private fun resolveOpenPayload(uri: Uri): Map<String, String>? {
        if (!isSupportedMediaUri(uri)) return null
        val displayName = queryDisplayName(uri) ?: uri.lastPathSegment ?: "audio"
        val path = when (uri.scheme?.lowercase()) {
            "file" -> uri.path?.takeIf { it.isNotEmpty() }
            "content" -> copyContentUriToCache(uri, displayName)
            else -> null
        } ?: return null
        return mapOf(
            "path" to path,
            "displayName" to displayName,
        )
    }

    private fun isSupportedMediaUri(uri: Uri): Boolean {
        val name = (queryDisplayName(uri) ?: uri.lastPathSegment ?: "").lowercase()
        if (name.endsWith(".wav") || name.endsWith(".mp4")) return true
        val mime = contentResolver.getType(uri)?.lowercase() ?: return false
        return mime == "audio/wav" ||
            mime == "audio/x-wav" ||
            mime == "audio/vnd.wave" ||
            mime == "video/mp4" ||
            mime == "audio/mp4" ||
            mime == "application/mp4"
    }

    private fun queryDisplayName(uri: Uri): String? {
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) {
                return cursor.getString(index)
            }
        }
        return null
    }

    private fun copyContentUriToCache(uri: Uri, displayName: String): String? {
        val safeName = displayName.replace(Regex("[^a-zA-Z0-9._-]"), "_")
        val outFile = File(cacheDir, "open_${System.currentTimeMillis()}_$safeName")
        return try {
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(outFile).use { output ->
                    input.copyTo(output)
                }
            }
            outFile.absolutePath
        } catch (_: Exception) {
            if (outFile.exists()) outFile.delete()
            null
        }
    }
}
