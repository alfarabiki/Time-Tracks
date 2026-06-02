package com.timeproof.app

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val storageChannel = "timeproof/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            storageChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "freeBytes" -> {
                    try {
                        val path = filesDir.absolutePath
                        val stat = StatFs(path)
                        val free = stat.availableBytes
                        result.success(free)
                    } catch (e: Exception) {
                        result.success(-1L)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
