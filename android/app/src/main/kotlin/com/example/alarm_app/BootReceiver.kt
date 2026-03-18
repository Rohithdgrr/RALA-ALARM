package com.example.alarm_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            
            // Start Flutter engine and notify about boot completion
            try {
                val flutterEngine = FlutterEngine(context)
                flutterEngine.dartExecutor.executeDartEntrypoint(
                    io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint.createDefault()
                )
                
                // Notify Flutter that boot completed
                val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.alarm_app/boot")
                channel.invokeMethod("onBootCompleted", null)
                
                // Stop the engine after notification
                flutterEngine.destroy()
            } catch (e: Exception) {
                // Fallback: just let flutter_local_notifications handle rescheduling
                // The plugin will automatically reschedule notifications on boot
            }
        }
    }
}
