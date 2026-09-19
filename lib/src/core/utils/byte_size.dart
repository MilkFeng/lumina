/// Formats a byte count the way a file manager does: `1.2 MB`, `512 KB`, `7 B`.
///
/// Lives in `core/` because more than one feature shows a file's size — the
/// external-source browser next to each entry, and the import progress dialog
/// next to the bytes a download has received — and two copies of this rounding
/// rule would drift apart.
String formatByteSize(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  // A whole number of bytes stays exact, and so does anything in the hundreds
  // (where a decimal would only eat width).
  final digits = value >= 100 || unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}
