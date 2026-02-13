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

                MainActivity.sendCallEvent(incomingNumber, "cellular")
            }
        }
    }
}
