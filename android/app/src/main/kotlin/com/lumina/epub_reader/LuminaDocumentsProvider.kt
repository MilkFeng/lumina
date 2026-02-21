package com.lumina.reader

import android.database.Cursor
import android.database.MatrixCursor
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import android.provider.DocumentsProvider
import android.webkit.MimeTypeMap
import java.io.File
import java.io.FileNotFoundException

/**
 * DocumentsProvider for Lumina to expose EPUB files and covers through Storage Access Framework.
 */
class LuminaDocumentsProvider : DocumentsProvider() {

    companion object {
        private const val ROOT_ID = "lumina_books_root"
        
        private val DEFAULT_ROOT_PROJECTION = arrayOf(
            DocumentsContract.Root.COLUMN_ROOT_ID,
            DocumentsContract.Root.COLUMN_FLAGS,
            DocumentsContract.Root.COLUMN_TITLE,
            DocumentsContract.Root.COLUMN_DOCUMENT_ID,
            DocumentsContract.Root.COLUMN_ICON,
            DocumentsContract.Root.COLUMN_SUMMARY
        )
        
        private val DEFAULT_DOCUMENT_PROJECTION = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            DocumentsContract.Document.COLUMN_FLAGS
        )
    }

    private fun getBaseDirectory(): File {
        val context = context ?: throw IllegalStateException("Context is null")
        val appFlutterDir = File(context.filesDir.parentFile, "app_flutter")
        
        if (!appFlutterDir.exists()) {
            appFlutterDir.mkdirs()
        }
        return appFlutterDir
    }

    override fun onCreate(): Boolean {
        return true
    }

    override fun queryRoots(projection: Array<out String>?): Cursor {
        val result = MatrixCursor(projection ?: DEFAULT_ROOT_PROJECTION)
        val context = context ?: return result

        result.newRow().apply {
            add(DocumentsContract.Root.COLUMN_ROOT_ID, ROOT_ID)
            add(DocumentsContract.Root.COLUMN_FLAGS, 0) 
            add(DocumentsContract.Root.COLUMN_TITLE, "Lumina Books")
            add(DocumentsContract.Root.COLUMN_DOCUMENT_ID, ROOT_ID)
            add(DocumentsContract.Root.COLUMN_ICON, R.mipmap.launcher_icon) 
            add(DocumentsContract.Root.COLUMN_SUMMARY, "Library & Covers")
        }

        return result
    }

    override fun queryDocument(documentId: String?, projection: Array<out String>?): Cursor {
        val result = MatrixCursor(projection ?: DEFAULT_DOCUMENT_PROJECTION)
        
        if (documentId == ROOT_ID) {
            val dir = getBaseDirectory()
            result.newRow().apply {
                add(DocumentsContract.Document.COLUMN_DOCUMENT_ID, ROOT_ID)
                add(DocumentsContract.Document.COLUMN_DISPLAY_NAME, "Lumina Books")
                add(DocumentsContract.Document.COLUMN_MIME_TYPE, DocumentsContract.Document.MIME_TYPE_DIR)
                add(DocumentsContract.Document.COLUMN_SIZE, 0)
                add(DocumentsContract.Document.COLUMN_LAST_MODIFIED, dir.lastModified())
                add(DocumentsContract.Document.COLUMN_FLAGS, 0)
            }
        } else {
            val file = getFileForDocId(documentId)
            includeFile(result, file)
        }
        return result
    }

    override fun queryChildDocuments(
        parentDocumentId: String?,
        projection: Array<out String>?,
        sortOrder: String?
    ): Cursor {
        val result = MatrixCursor(projection ?: DEFAULT_DOCUMENT_PROJECTION)
        val parent = getFileForDocId(parentDocumentId)

        parent.listFiles()?.forEach { file ->
            if (parentDocumentId == ROOT_ID) {
                if (file.isDirectory && (file.name == "books" || file.name == "covers")) {
                    includeFile(result, file)
                }
            } else {
                includeFile(result, file)
            }
        }

        return result
    }

    override fun openDocument(
        documentId: String?,
        mode: String?,
        signal: CancellationSignal?
    ): ParcelFileDescriptor {
        val file = getFileForDocId(documentId)
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    private fun getDocIdForFile(file: File): String {
        val baseDir = getBaseDirectory()
        val path = file.absolutePath
        val basePath = baseDir.absolutePath
        
        return if (path == basePath) {
            ROOT_ID
        } else {
            // 截取掉 base 路径，保留相对路径
            path.substring(basePath.length + 1)
        }
    }

    private fun getFileForDocId(docId: String?): File {
        val baseDir = getBaseDirectory()
        
        if (docId == null || docId == ROOT_ID) {
            return baseDir
        }
        
        val file = File(baseDir, docId)
        
        // 防御路径穿越攻击 (e.g. docId = "../../../system")
        if (!file.canonicalPath.startsWith(baseDir.canonicalPath)) {
            throw SecurityException("Invalid document ID")
        }
        if (!file.exists()) {
            throw FileNotFoundException("File not found: $docId")
        }
        
        return file
    }

    private fun includeFile(result: MatrixCursor, file: File) {
        var flags = 0
        if (file.isFile) {
            flags = DocumentsContract.Document.FLAG_SUPPORTS_COPY
        }

        val displayName = file.name
        
        val mimeType = if (file.isDirectory) {
            DocumentsContract.Document.MIME_TYPE_DIR
        } else {
            val extension = file.extension.lowercase()
            when (extension) {
                "epub" -> "application/epub+zip"
                else -> MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension) 
                        ?: "application/octet-stream"
            }
        }

        result.newRow().apply {
            add(DocumentsContract.Document.COLUMN_DOCUMENT_ID, getDocIdForFile(file))
            add(DocumentsContract.Document.COLUMN_DISPLAY_NAME, displayName)
            add(DocumentsContract.Document.COLUMN_MIME_TYPE, mimeType)
            add(DocumentsContract.Document.COLUMN_SIZE, if (file.isDirectory) 0 else file.length())
            add(DocumentsContract.Document.COLUMN_LAST_MODIFIED, file.lastModified())
            add(DocumentsContract.Document.COLUMN_FLAGS, flags)
        }
    }
}