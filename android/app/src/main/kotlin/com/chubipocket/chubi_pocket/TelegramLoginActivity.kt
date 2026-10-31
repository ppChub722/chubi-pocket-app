package com.chubipocket.chubi_pocket

import android.app.Activity
import android.os.Bundle

/** Catches the Telegram login redirect, hands it to Flutter, brings the app's own task back. */
class TelegramLoginActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.data?.let { MainActivity.deliver(it.toString()) }
        packageManager.getLaunchIntentForPackage(packageName)?.let { startActivity(it) }
        finish()
    }
}
