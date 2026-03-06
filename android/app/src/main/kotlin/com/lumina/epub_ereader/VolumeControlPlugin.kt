package com.lumina.ereader

import android.view.KeyEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VolumeControlPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    
    private var eventSink: EventChannel.EventSink? = null
    private var isIntercepting = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "lumina/volume_control")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "lumina/volume_events")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enableInterception" -> {
                isIntercepting = true
                result.success(null)
            }
            "disableInterception" -> {
                isIntercepting = false
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun processKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (isIntercepting) {
            when (keyCode) {
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    eventSink?.success("down")
                    return true
                }
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    eventSink?.success("up")
                    return true
                }
            }
        }
        return false
    }
}