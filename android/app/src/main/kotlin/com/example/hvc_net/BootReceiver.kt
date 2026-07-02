package com.example.hvc_net

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            // Start your service on boot
            val serviceIntent = Intent(context, ForegroundService::class.java)
            serviceIntent.action = ForegroundService.ACTION_START
            context.startService(serviceIntent)
        }
    }
}