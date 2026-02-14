package br.com.hostaraguaia.bina_intercept

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

class CallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            if (state == TelephonyManager.EXTRA_STATE_RINGING) {
                var incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
                Log.d("BinaIntercept", "Incoming call extra: $incomingNumber")

                if (incomingNumber.isNullOrEmpty()) {
                     Log.w("BinaIntercept", "Incoming number is null or empty. Ignoring call.")
                     return
                }

                // Try to send to UI if active
                if (MainActivity.channel != null) {
                    MainActivity.sendCallEvent(incomingNumber, "cellular")
                } else {
                    Log.d("BinaIntercept", "UI channel is null, saving to SharedPrefs for background service")
                    // Save to SharedPrefs for Background Service to pick up
                    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    prefs.edit().putString("flutter.background_incoming_call", incomingNumber).apply()
                    prefs.edit().putLong("flutter.background_incoming_call_timestamp", System.currentTimeMillis()).apply()
                }
            }
        }
    }
}
