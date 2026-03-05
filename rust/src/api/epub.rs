use std::collections::HashMap;
use std::fs::File;
use std::io::{BufReader, Read};

use once_cell::sync::Lazy;
use parking_lot::RwLock;
use zip::ZipArchive;

// ---------------------------------------------------------------------------
// Global index store
//
// epub_path  →  (normalized_entry_name  →  zip_entry_index)
//
// `load_epub` only builds this index (fast: just reads the ZIP central
// directory).  No file content is decompressed or buffered here.
//
// Each `read_epub_file` call:
//   1. Holds the READ lock for a microsecond to look up the entry index.
//   2. Releases the lock.
//   3. Opens its own file handle and decompresses independently.
//      → N concurrent requests decompress in parallel without any locking.
// ---------------------------------------------------------------------------
static EPUB_INDEX: Lazy<RwLock<HashMap<String, HashMap<String, usize>>>> =
    Lazy::new(|| RwLock::new(HashMap::new()));

// ---------------------------------------------------------------------------
// Public API (called from Dart via flutter_rust_bridge)
// ---------------------------------------------------------------------------

/// Build the name→index table for the EPUB at `epub_path`.
///
/// Only reads the ZIP Central Directory (located at the end of the file).
/// No file content is decompressed.  Idempotent: a second call for the same
/// path is a no-op.
pub fn load_epub(epub_path: String) -> Result<(), String> {
    // Fast path: already indexed.
    {
        let guard = EPUB_INDEX.read();
        if guard.contains_key(&epub_path) {
            return Ok(());
        }
    }

    // Build index (slow path, done once per book).
    let file =
        File::open(&epub_path).map_err(|e| format!("load_epub: cannot open file: {e}"))?;
    let reader = BufReader::new(file);
    let archive =
        ZipArchive::new(reader).map_err(|e| format!("load_epub: invalid ZIP/EPUB: {e}"))?;

    let mut index: HashMap<String, usize> = HashMap::with_capacity(archive.len());

    // Collect entry names without decompressing.
    // `file_names()` iterates the central directory in the same order as
    // `by_index(i)`, so position i == central-directory position i.
    for (i, name) in archive.file_names().enumerate() {
        // Normalise to forward-slashes so both "OEBPS/image.png" and
        // "OEBPS\\image.png" look up correctly.
        let normalised = name.replace('\\', "/");
        index.insert(normalised, i);
    }

    let mut guard = EPUB_INDEX.write();
    // Check again inside write lock (another thread may have loaded it).
    guard.entry(epub_path).or_insert(index);

    Ok(())
}

/// Read a single file from the EPUB (lazy: decompresses only the requested
/// entry).
///
/// Concurrency:
///   * The read lock is held **only** while looking up the entry index
///     (HashMap get, O(1), < 1 µs).
///   * The actual decompression happens after the lock is released, so many
///     callers can decompress different entries at the same time.
pub fn read_epub_file(
    epub_path: String,
    file_path: String,
) -> Result<Option<Vec<u8>>, String> {
    let normalised_path = file_path.replace('\\', "/");

    // --- 1. Look up entry index (READ lock, held for microseconds) ----------
    let entry_index: usize = {
        let guard = EPUB_INDEX.read();
        let index = guard
            .get(&epub_path)
            .ok_or_else(|| "read_epub_file: EPUB not loaded; call load_epub first".to_string())?;

        match index.get(&normalised_path).copied() {
            Some(i) => i,
            None => return Ok(None), // file not found in this EPUB
        }
    };
    // READ LOCK RELEASED HERE ------------------------------------------------

    // --- 2. Open file, create archive, decompress entry (no lock held) ------
    let file =
        File::open(&epub_path).map_err(|e| format!("read_epub_file: cannot open file: {e}"))?;
    let reader = BufReader::new(file);
    let mut archive = ZipArchive::new(reader)
        .map_err(|e| format!("read_epub_file: cannot read ZIP: {e}"))?;

    let mut zip_entry = archive
        .by_index(entry_index)
        .map_err(|e| format!("read_epub_file: bad entry index {entry_index}: {e}"))?;

    let capacity = zip_entry.size() as usize;
    let mut buf = Vec::with_capacity(capacity);
    zip_entry
        .read_to_end(&mut buf)
        .map_err(|e| format!("read_epub_file: decompression error: {e}"))?;

    Ok(Some(buf))
}

/// Remove an EPUB's index from memory.
/// Call this when the reader is closed to free memory.
pub fn close_epub(epub_path: String) {
    let mut guard = EPUB_INDEX.write();
    guard.remove(&epub_path);
}
