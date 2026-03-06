package com.lumina.ereader

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import androidx.activity.result.ActivityResult
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.ActivityResultRegistryOwner
import androidx.activity.result.contract.ActivityResultContracts
import androidx.documentfile.provider.DocumentFile
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * FlutterPlugin that provides a MethodChannel for EPUB file/folder picking
 * using Android SAF (Storage Access Framework).
 *
 * Extracted from MainActivity to keep the entry point clean. All folder
 * traversal happens on background threads via Kotlin Coroutines to avoid ANRs.
 */
class NativePickerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null

    private var pickFilesLauncher: ActivityResultLauncher<Intent>? = null
    private var pickFolderLauncher: ActivityResultLauncher<Intent>? = null
    private var pickBackupFolderLauncher: ActivityResultLauncher<Intent>? = null
    private var pickFontFilesLauncher: ActivityResultLauncher<Intent>? = null

    // -------------------------------------------------------------------------
    // FlutterPlugin
    // -------------------------------------------------------------------------

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // -------------------------------------------------------------------------
    // ActivityAware
    // -------------------------------------------------------------------------

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        registerLaunchers(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        clearLaunchers()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        registerLaunchers(binding.activity)
    }

    override fun onDetachedFromActivity() {
        activity = null
        clearLaunchers()
    }

    // -------------------------------------------------------------------------
    // MethodCallHandler
    // -------------------------------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "pickEpubFiles" -> pickEpubFiles(result)
            "pickEpubFolder" -> pickEpubFolder(result)
            "pickBackupFolder" -> pickBackupFolder(result)
            "pickFontFiles" -> pickFontFiles(result)
            else -> result.notImplemented()
        }
    }

    // -------------------------------------------------------------------------
    // Launcher registration
    // -------------------------------------------------------------------------

    private fun registerLaunchers(activity: Activity) {
        val registryOwner = activity as? ActivityResultRegistryOwner ?: return
        val lifecycleOwner = activity as? LifecycleOwner ?: return

        val registry = registryOwner.activityResultRegistry

        pickFilesLauncher = registry.register(
            "NativePickerPlugin_pickFiles",
            lifecycleOwner,
            ActivityResultContracts.StartActivityForResult()
        ) { result: ActivityResult ->
            val pendingResult = this.pendingResult ?: return@register
            this.pendingResult = null
            if (result.resultCode == Activity.RESULT_OK && result.data != null) {
                handlePickFilesResult(result.data!!, pendingResult)
            } else {
                pendingResult.success(emptyList<String>())
            }
        }

        pickFolderLauncher = registry.register(
            "NativePickerPlugin_pickFolder",
            lifecycleOwner,
            ActivityResultContracts.StartActivityForResult()
        ) { result: ActivityResult ->
            val pendingResult = this.pendingResult ?: return@register
            this.pendingResult = null
            if (result.resultCode == Activity.RESULT_OK && result.data != null) {
                handlePickFolderResult(result.data!!, pendingResult)
            } else {
                pendingResult.success(emptyList<String>())
            }
        }

        pickBackupFolderLauncher = registry.register(
            "NativePickerPlugin_pickBackupFolder",
            lifecycleOwner,
            ActivityResultContracts.StartActivityForResult()
        ) { result: ActivityResult ->
            val pendingResult = this.pendingResult ?: return@register
            this.pendingResult = null
            if (result.resultCode == Activity.RESULT_OK && result.data != null) {
                handlePickBackupFolderResult(result.data!!, pendingResult)
            } else {
                pendingResult.success(emptyList<String>())
            }
        }

        pickFontFilesLauncher = registry.register(
            "NativePickerPlugin_pickFontFiles",
            lifecycleOwner,
            ActivityResultContracts.StartActivityForResult()
        ) { result: ActivityResult ->
            val pendingResult = this.pendingResult ?: return@register
            this.pendingResult = null
            if (result.resultCode == Activity.RESULT_OK && result.data != null) {
                handlePickFontFilesResult(result.data!!, pendingResult)
            } else {
                pendingResult.success(emptyList<String>())
            }
        }
    }

    private fun clearLaunchers() {
        pickFilesLauncher = null
        pickFolderLauncher = null
        pickBackupFolderLauncher = null
        pickFontFilesLauncher = null
    }

    // -------------------------------------------------------------------------
    // Picker launch helpers
    // -------------------------------------------------------------------------

    /**
     * Launches file picker for selecting multiple EPUB and PDF files.
     *
     * Uses ACTION_OPEN_DOCUMENT with MIME types for both EPUB and PDF.
     * Allows multiple file selection.
     */
    private fun pickEpubFiles(result: Result) {
        if (pendingResult != null) {
            result.error("ALREADY_ACTIVE", "File picker is already active", null)
            return
        }

        pendingResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            // Support both EPUB and PDF files
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("application/epub+zip", "application/pdf", "application/octet-stream")
            )
        }

        try {
            pickFilesLauncher?.launch(intent)
                ?: run {
                    pendingResult = null
                    result.error("NO_ACTIVITY", "Plugin not attached to an activity", null)
                }
        } catch (e: Exception) {
            pendingResult = null
            result.error("PICKER_ERROR", "Failed to launch file picker: ${e.message}", null)
        }
    }

    /**
     * Launches folder picker for selecting a directory containing EPUB files.
     *
     * Uses ACTION_OPEN_DOCUMENT_TREE. Folder traversal happens in a background
     * thread using Kotlin Coroutines to avoid blocking the main thread.
     */
    private fun pickEpubFolder(result: Result) {
        if (pendingResult != null) {
            result.error("ALREADY_ACTIVE", "Folder picker is already active", null)
            return
        }

        pendingResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }

        try {
            pickFolderLauncher?.launch(intent)
                ?: run {
                    pendingResult = null
                    result.error("NO_ACTIVITY", "Plugin not attached to an activity", null)
                }
        } catch (e: Exception) {
            pendingResult = null
            result.error("PICKER_ERROR", "Failed to launch folder picker: ${e.message}", null)
        }
    }

    /**
     * Launches folder picker for selecting a Lumina backup directory.
     *
     * Returns a list of all file URIs inside the chosen directory tree.
     */
    private fun pickBackupFolder(result: Result) {
        if (pendingResult != null) {
            result.error("ALREADY_ACTIVE", "Folder picker is already active", null)
            return
        }

        pendingResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        try {
            pickBackupFolderLauncher?.launch(intent)
                ?: run {
                    pendingResult = null
                    result.error("NO_ACTIVITY", "Plugin not attached to an activity", null)
                }
        } catch (e: Exception) {
            pendingResult = null
            result.error("PICKER_ERROR", "Failed to launch folder picker: ${e.message}", null)
        }
    }

    /**
     * Launches file picker for selecting multiple font files (.ttf / .otf).
     *
     * Uses ACTION_OPEN_DOCUMENT with font MIME types to present a filtered
     * file picker. Falls back to application/octet-stream for devices that
     * do not recognize font MIME types.
     */
    private fun pickFontFiles(result: Result) {
        if (pendingResult != null) {
            result.error("ALREADY_ACTIVE", "File picker is already active", null)
            return
        }

        pendingResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf(
                    "font/ttf",
                    "font/otf",
                    "application/x-font-ttf",
                    "application/x-font-otf",
                    "application/octet-stream"
                )
            )
        }

        try {
            pickFontFilesLauncher?.launch(intent)
                ?: run {
                    pendingResult = null
                    result.error("NO_ACTIVITY", "Plugin not attached to an activity", null)
                }
        } catch (e: Exception) {
            pendingResult = null
            result.error("PICKER_ERROR", "Failed to launch font picker: ${e.message}", null)
        }
    }

    // -------------------------------------------------------------------------
    // Activity result handlers
    // -------------------------------------------------------------------------

    /**
     * Handles the result of the file picker.
     *
     * Extracts URIs from single or multiple file selection and filters for
     * valid EPUB files. Runs the heavy ContentResolver work on Dispatchers.IO.
     */
    private fun handlePickFilesResult(data: Intent, result: Result) {
        val lifecycleOwner = activity as? LifecycleOwner ?: run {
            result.error("NO_ACTIVITY", "Plugin not attached to an activity", null)
            return
        }

        lifecycleOwner.lifecycleScope.launch {
            try {
                val uris = withContext(Dispatchers.IO) {
                    val validUris = mutableListOf<String>()

                    // Multiple files
                    data.clipData?.let { clipData ->
                        for (i in 0 until clipData.itemCount) {
                            val uri = clipData.getItemAt(i).uri
                            if (isEpubFile(uri)) validUris.add(uri.toString())
                        }
                    }

                    // Single file fallback
                    if (validUris.isEmpty()) {
                        data.data?.let { uri ->
                            if (isEpubFile(uri)) validUris.add(uri.toString())
                        }
                    }

                    validUris
                }
                result.success(uris)
            } catch (e: Exception) {
                result.error(
                    "FILE_PROCESS_ERROR",
                    "Failed to process selected files: ${e.message}",
                    null
                )
            }
        }
    }

    /**
     * Handles the result of the EPUB folder picker.
     *
     * Recursively traverses the selected folder in a background thread to find
     * all EPUB files without blocking the main thread.
     */
    private fun handlePickFolderResult(data: Intent, result: Result) {
        val treeUri = data.data ?: run {
            result.success(emptyList<String>())
            return
        }

        val lifecycleOwner = activity as? LifecycleOwner ?: run {
            result.error("NO_ACTIVITY", "Plugin not attached to an activity", null)
            return
        }

        try {
            activity?.contentResolver?.takePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (_: Exception) {
            // Permission might not be persistable, continue anyway
        }

        lifecycleOwner.lifecycleScope.launch {
            try {
                val epubUris = withContext(Dispatchers.IO) { traverseFolderForEpubs(treeUri) }
                result.success(epubUris)
            } catch (e: Exception) {
                result.error(
                    "TRAVERSAL_ERROR",
                    "Failed to traverse folder: ${e.message}",
                    null
                )
            }
        }
    }

    /**
     * Handles the result of the backup folder picker.
     *
     * Collects all file URIs inside the chosen directory tree.
     */
    private fun handlePickBackupFolderResult(data: Intent, result: Result) {
        val treeUri = data.data ?: run {
            result.success(emptyList<String>())
            return
        }

        val lifecycleOwner = activity as? LifecycleOwner ?: run {
            result.error("NO_ACTIVITY", "Plugin not attached to an activity", null)
            return
        }

        try {
            activity?.contentResolver?.takePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (_: Exception) {
            // Permission might not be persistable, continue anyway
        }

        lifecycleOwner.lifecycleScope.launch {
            try {
                val uris = withContext(Dispatchers.IO) { traverseFolderForBackupFiles(treeUri) }
                result.success(uris)
            } catch (e: Exception) {
                result.error(
                    "TRAVERSAL_ERROR",
                    "Failed to traverse folder: ${e.message}",
                    null
                )
            }
        }
    }

    /**
     * Handles the result of the font file picker.
     *
     * Extracts URIs from single or multiple file selection and filters for
     * valid font files (.ttf / .otf). Runs ContentResolver work on Dispatchers.IO.
     */
    private fun handlePickFontFilesResult(data: Intent, result: Result) {
        val lifecycleOwner = activity as? LifecycleOwner ?: run {
            result.error("NO_ACTIVITY", "Plugin not attached to an activity", null)
            return
        }

        lifecycleOwner.lifecycleScope.launch {
            try {
                val uris = withContext(Dispatchers.IO) {
                    val validUris = mutableListOf<String>()

                    // Multiple files
                    data.clipData?.let { clipData ->
                        for (i in 0 until clipData.itemCount) {
                            val uri = clipData.getItemAt(i).uri
                            if (isFontFile(uri)) validUris.add(uri.toString())
                        }
                    }

                    // Single file fallback
                    if (validUris.isEmpty()) {
                        data.data?.let { uri ->
                            if (isFontFile(uri)) validUris.add(uri.toString())
                        }
                    }

                    validUris
                }
                result.success(uris)
            } catch (e: Exception) {
                result.error(
                    "FILE_PROCESS_ERROR",
                    "Failed to process selected font files: ${e.message}",
                    null
                )
            }
        }
    }

    // -------------------------------------------------------------------------
    // Folder traversal helpers  (run on Dispatchers.IO)
    // -------------------------------------------------------------------------

    private fun traverseFolderForEpubs(treeUri: Uri): List<String> {
        val activity = this.activity ?: return emptyList()
        val epubUris = mutableListOf<String>()
        val documentFile = DocumentFile.fromTreeUri(activity, treeUri) ?: return epubUris

        val queue = ArrayDeque<DocumentFile>()
        queue.add(documentFile)

        while (queue.isNotEmpty()) {
            val current = queue.removeFirst()
            try {
                if (current.isDirectory) {
                    current.listFiles().forEach { queue.add(it) }
                } else if (current.isFile) {
                    val name = current.name ?: ""
                    if (name.endsWith(".epub", ignoreCase = true) || 
                        name.endsWith(".pdf", ignoreCase = true)) {
                        epubUris.add(current.uri.toString())
                    }
                }
            } catch (_: Exception) {
                // Skip inaccessible entries
            }
        }

        return epubUris
    }

    private fun traverseFolderForBackupFiles(treeUri: Uri): List<String> {
        val activity = this.activity ?: return emptyList()
        val uris = mutableListOf<String>()
        val documentFile = DocumentFile.fromTreeUri(activity, treeUri) ?: return uris

        val queue = ArrayDeque<DocumentFile>()
        queue.add(documentFile)

        while (queue.isNotEmpty()) {
            val current = queue.removeFirst()
            try {
                if (current.isDirectory) {
                    current.listFiles().forEach { queue.add(it) }
                } else if (current.isFile) {
                    uris.add(current.uri.toString())
                }
            } catch (_: Exception) {
                // Skip inaccessible entries
            }
        }

        return uris
    }

    // -------------------------------------------------------------------------
    // File validation helpers  (run on Dispatchers.IO)
    // -------------------------------------------------------------------------

    private fun isEpubFile(uri: Uri): Boolean {
        val activity = this.activity ?: return false

        val displayName = try {
            activity.contentResolver.query(
                uri,
                arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null, null, null
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            }
        } catch (_: Exception) {
            null
        }

        if (displayName?.endsWith(".epub", ignoreCase = true) == true) return true
        if (displayName?.endsWith(".pdf", ignoreCase = true) == true) return true

        val mimeType = activity.contentResolver.getType(uri)
        return mimeType == "application/epub+zip" || mimeType == "application/pdf"
    }

    private fun isFontFile(uri: Uri): Boolean {
        val activity = this.activity ?: return false

        val displayName = try {
            activity.contentResolver.query(
                uri,
                arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null, null, null
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            }
        } catch (_: Exception) {
            null
        }

        if (displayName != null) {
            val lower = displayName.lowercase()
            if (lower.endsWith(".ttf") || lower.endsWith(".otf")) return true
        }

        val mimeType = activity.contentResolver.getType(uri)
        return mimeType != null && (
            mimeType == "font/ttf" ||
            mimeType == "font/otf" ||
            mimeType == "application/x-font-ttf" ||
            mimeType == "application/x-font-otf"
        )
    }

    // -------------------------------------------------------------------------
    // Companion
    // -------------------------------------------------------------------------

    companion object {
        const val CHANNEL_NAME = "com.lumina.ereader/native_picker"
    }
}
