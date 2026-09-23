package com.lumina.ereader

import android.app.Activity
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Silences the haptic feedback the platform WebView plays on its own.
 *
 * A long press inside a WebView is handled by Android/Chromium itself, and a
 * long press that was handled makes [View] play
 * [android.view.HapticFeedbackConstants.LONG_PRESS] — whether or not the page
 * wanted anything to happen.  The reader detects its image long press inside the
 * page (see `GestureObserver` in `web_assets/controller.js`), so that buzz is an
 * artefact of the browser rather than a signal the reader asked for, and it also
 * fires on presses that hit nothing actionable at all.
 *
 * Vibration is Flutter's to decide (`HapticFeedback` in the reader), and
 * [View.setHapticFeedbackEnabled] is the one lever that suppresses the
 * framework's own call.  It is not reachable from Dart: `flutter_inappwebview`
 * exposes a view id, never the view, and no `InAppWebViewSettings` maps to it.
 */
class ReaderHapticsPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private lateinit var methodChannel: MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, "lumina/reader_haptics")
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "muteWebViewHaptics" -> result.success(muteWebViewHaptics())
            else -> result.notImplemented()
        }
    }

    /**
     * Mutes every WebView in the window and reports how many were found.
     *
     * The count is what the caller retries on.  The reader's WebView is the
     * pre-warmed one, handed over to the visible platform view, and a WebView
     * that is not attached to the window yet cannot be found by walking it —
     * so the first call after the platform view is created may well find none.
     *
     * Every WebView is muted rather than only the reader's: the reader is the
     * only place in this app that embeds web content, and the pre-warm is the
     * same instance the reader ends up showing.
     */
    private fun muteWebViewHaptics(): Int {
        val root = activity?.window?.decorView ?: return 0

        val webViews = mutableListOf<WebView>()
        collectWebViews(root, webViews)

        for (webView in webViews) {
            // `View.performHapticFeedback` reads the flag on the view that
            // performs the call, so set it on the WebView and on its subtree:
            // the buzz has to stop whichever of them Android ends up calling.
            webView.isHapticFeedbackEnabled = false
            muteSubtree(webView)
        }

        return webViews.size
    }

    private fun collectWebViews(view: View, into: MutableList<WebView>) {
        if (view is WebView) {
            into.add(view)
        }
        if (view is ViewGroup) {
            for (index in 0 until view.childCount) {
                collectWebViews(view.getChildAt(index), into)
            }
        }
    }

    private fun muteSubtree(view: View) {
        view.isHapticFeedbackEnabled = false
        if (view is ViewGroup) {
            for (index in 0 until view.childCount) {
                muteSubtree(view.getChildAt(index))
            }
        }
    }
}
