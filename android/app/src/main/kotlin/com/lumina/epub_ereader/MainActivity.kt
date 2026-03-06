package com.lumina.ereader

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private val volumeControlPlugin = VolumeControlPlugin()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(NativePickerPlugin())
        flutterEngine.plugins.add(volumeControlPlugin)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (volumeControlPlugin.processKeyDown(keyCode, event)) {
            return true 
        }
        return super.onKeyDown(keyCode, event)
    }
}
