package com.frasesstatus.frases_status

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "frases_status/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "instagramStory" -> {
                        val path = call.argument<String>("path")
                        result.success(shareToInstagramStory(path))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Posta a imagem direto nos Stories do Instagram. Retorna false se o
    /// Instagram não estiver instalado (o Dart cai no fallback).
    private fun shareToInstagramStory(path: String?): Boolean {
        if (path.isNullOrEmpty()) return false
        return try {
            val file = File(path)
            if (!file.exists()) return false
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file
            )
            val intent = Intent("com.instagram.share.ADD_TO_STORY").apply {
                setDataAndType(uri, "image/png")
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
                putExtra("source_application", packageName)
            }
            if (intent.resolveActivity(packageManager) == null) {
                return false
            }
            grantUriPermission(
                "com.instagram.android",
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
