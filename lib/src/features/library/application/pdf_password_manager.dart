import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages secure storage of PDF passwords using the device's secure storage
/// (Keychain on iOS, Keystore on Android)
class PdfPasswordManager {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const _passwordKeyPrefix = 'pdf_password_';

  /// Save password with unique key for each book
  /// [fileHash] - SHA-256 hash of the PDF file, used as unique identifier
  /// [password] - The password to store securely
  Future<void> savePassword(String fileHash, String password) async {
    await _secureStorage.write(
      key: '$_passwordKeyPrefix$fileHash',
      value: password,
    );
  }

  /// Retrieve password for a specific book
  /// Returns null if no password is stored for the given file hash
  Future<String?> getPassword(String fileHash) async {
    return await _secureStorage.read(
      key: '$_passwordKeyPrefix$fileHash',
    );
  }

  /// Check if a password is stored for a specific book
  Future<bool> hasPassword(String fileHash) async {
    final password = await getPassword(fileHash);
    return password != null;
  }

  /// Delete password for a specific book (e.g., when book is deleted)
  Future<void> deletePassword(String fileHash) async {
    await _secureStorage.delete(
      key: '$_passwordKeyPrefix$fileHash',
    );
  }

  /// Delete all stored PDF passwords (useful for data clearing)
  Future<void> deleteAllPasswords() async {
    await _secureStorage.deleteAll();
  }
}