package com.lumina.reader

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.DocumentsContract
import androidx.activity.result.ActivityResult
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import androidx.lifecycle.lifecycleScope

/**
 * MainActivity with native file picker implementation
 * 
 * Provides MethodChannel for EPUB file/folder picking using Android SAF.
 * All folder traversal happens in background threads using Kotlin Coroutines
 * to avoid ANRs on the main thread.
 */
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.lumina.reader/native_picker"
    private var methodChannel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null

    // Activity result launchers - initialized in onCreate
    private lateinit var pickFilesLauncher: ActivityResultLauncher<Intent>
    private lateinit var pickFolderLauncher: ActivityResultLauncher<Intent>

    override fun onCreate(savedInstanceState: Bundle?) {
        // Register activity result launchers BEFORE calling super.onCreate()
        pickFilesLauncher = registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { result: ActivityResult ->
            val pendingResult = this.pendingResult ?: return@registerForActivityResult
            this.pendingResult = null

            if (result.resultCode == RESULT_OK && result.data != null) {
                handlePickFilesResult(result.data!!, pendingResult)
            } else {
                pendingResult.success(emptyList<String>())
            }
        }

        pickFolderLauncher = registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { result: ActivityResult ->
            val pendingResult = this.pendingResult ?: return@registerForActivityResult
            this.pendingResult = null

            if (result.resultCode == RESULT_OK && result.data != null) {
                handlePickFolderResult(result.data!!, pendingResult)
            } else {
                pendingResult.success(emptyList<String>())
            }
        }

        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickEpubFiles" -> {
                    pickEpubFiles(result)
                }
                "pickEpubFolder" -> {
                    pickEpubFolder(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        super.onDestroy()
    }

    /**
     * Launches file picker for selecting multiple EPUB files
     * 
     * Uses ACTION_OPEN_DOCUMENT with MIME type application/epub+zip.
     * Allows multiple file selection.
     */
    private fun pickEpubFiles(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("ALREADY_ACTIVE", "File picker is already active", null)
            return
        }

        pendingResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/epub+zip"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            // Fallback to all files if EPUB MIME type is not recognized
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/epub+zip", "application/octet-stream"))
        }

        try {
            pickFilesLauncher.launch(intent)
        } catch (e: Exception) {
            pendingResult = null
            result.error("PICKER_ERROR", "Failed to launch file picker: ${e.message}", null)
        }
    }

    /**
     * Launches folder picker for selecting a directory containing EPUB files
     * 
     * Uses ACTION_OPEN_DOCUMENT_TREE to let user select a folder.
     * Folder traversal happens in background thread using Kotlin Coroutines
     * to avoid blocking the main thread.
     */
    private fun pickEpubFolder(result: MethodChannel.Result) {
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
            pickFolderLauncher.launch(intent)
        } catch (e: Exception) {
            pendingResult = null
            result.error("PICKER_ERROR", "Failed to launch folder picker: ${e.message}", null)
        }
    }

    /**
     * Handles the result of file picker
     * 
     * Extracts URIs from single or multiple file selection.
     */
    private fun handlePickFilesResult(data: Intent, result: MethodChannel.Result) {
        // Launch a coroutine on the Main dispatcher, but offload heavy work to IO
        lifecycleScope.launch {
            try {
                val uris = withContext(Dispatchers.IO) {
                    val validUris = mutableListOf<String>()

                    // Handle multiple files
                    data.clipData?.let { clipData ->
                        for (i in 0 until clipData.itemCount) {
                            val uri = clipData.getItemAt(i).uri
                            // isEpubFile does IPC via ContentResolver, must run in IO thread
                            if (isEpubFile(uri)) {
                                validUris.add(uri.toString())
                            }
                        }
                    }

                    // Handle single file (if clipData is null but data has a URI)
                    if (validUris.isEmpty()) {
                        data.data?.let { uri ->
                            if (isEpubFile(uri)) {
                                validUris.add(uri.toString())
                            }
                        }
                    }
                    
                    validUris
                }
                
                // Return result on the Main thread
                result.success(uris)
                
            } catch (e: Exception) {
                result.error("FILE_PROCESS_ERROR", "Failed to process selected files: ${e.message}", null)
            }
        }
    }

    /**
     * Handles the result of folder picker
     * 
     * Recursively traverses the selected folder in a background thread
     * using Kotlin Coroutines to find all EPUB files without blocking
     * the main thread.
     */
    private fun handlePickFolderResult(data: Intent, result: MethodChannel.Result) {
        val treeUri = data.data ?: run {
            result.success(emptyList<String>())
            return
        }

        // Take persistable permissions for future access if needed
        try {
            contentResolver.takePersistableUriPermission(
                treeUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (e: Exception) {
            // Permission might not be persistable, continue anyway
        }

        // Traverse folder in background thread
        lifecycleScope.launch {
            try {
                val epubUris = withContext(Dispatchers.IO) {
                    traverseFolderForEpubs(treeUri)
                }
                result.success(epubUris)
            } catch (e: Exception) {
                result.error("TRAVERSAL_ERROR", "Failed to traverse folder: ${e.message}", null)
            }
        }
    }

    /**
     * Recursively traverses a DocumentFile tree to find all EPUB files
     * 
     * RUNS ON BACKGROUND THREAD (Dispatchers.IO)
     * This prevents ANRs when scanning large folder structures.
     * 
     * @param treeUri The root folder URI to traverse
     * @return List of EPUB file URIs found in the folder tree
     */
    private fun traverseFolderForEpubs(treeUri: Uri): List<String> {
        val epubUris = mutableListOf<String>()
        val documentFile = DocumentFile.fromTreeUri(this, treeUri) ?: return epubUris

        // Use a queue for iterative traversal to avoid deep recursion
        val queue = ArrayDeque<DocumentFile>()
        queue.add(documentFile)

        while (queue.isNotEmpty()) {
            val current = queue.removeFirst()

            try {
                if (current.isDirectory) {
                    // Add subdirectories to queue
                    current.listFiles().forEach { child ->
                        queue.add(child)
                    }
                } else if (current.isFile) {
                    // Check if it's an EPUB file
                    val name = current.name ?: ""
                    if (name.endsWith(".epub", ignoreCase = true)) {
                        epubUris.add(current.uri.toString())
                    }
                }
            } catch (e: Exception) {
                // Skip files/folders that can't be accessed
                continue
            }
        }

        return epubUris
    }

    /**
     * Checks if a URI points to an EPUB file
     * 
     * Checks both file extension and MIME type.
     */
    private fun isEpubFile(uri: Uri): Boolean {
        // Check file extension from display name
        val displayName = try {
            contentResolver.query(uri, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(0)
                } else null
            }
        } catch (e: Exception) {
            null
        }

        if (displayName?.endsWith(".epub", ignoreCase = true) == true) {
            return true
        }

        // Check MIME type
        val mimeType = contentResolver.getType(uri)
        return mimeType == "application/epub+zip"
    }
}
