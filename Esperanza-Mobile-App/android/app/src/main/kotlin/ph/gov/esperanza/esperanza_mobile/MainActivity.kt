package ph.gov.esperanza.esperanza_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The channel push notifications arrive on (2026-10-15): named, so a
        // resident can find and adjust it in the phone's settings.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "esperanza_updates",
                "Request updates",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply { description = "Updates on your requests, documents and account from the Municipality of Esperanza" }
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
        }
    }
}
