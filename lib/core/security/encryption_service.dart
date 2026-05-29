import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Client-side AES-256-CBC encryption service.
///
/// Call [initialize] once in main() before any read/write to Firebase.
/// All patient-sensitive fields are passed through [encrypt] before leaving
/// the device and through [decrypt] after retrieval.
class EncryptionService {
  EncryptionService._();

  static const String _keyStorageKey = 'mediq_aes256_key_v1';

  static const FlutterSecureStorage _store = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static late Key _key;
  static bool _initialized = false;

  // ─── Initialization ────────────────────────────────────────────────────────

  /// Must be called once at app startup (in main()) before any encrypt/decrypt.
  static Future<void> initialize() async {
    if (_initialized) return;

    final stored = await _store.read(key: _keyStorageKey);
    if (stored != null) {
      // Existing install — restore key.
      _key = Key(base64Decode(stored));
    } else {
      // First run — generate a cryptographically secure 256-bit (32-byte) key.
      final bytes = _secureRandomBytes(32);
      await _store.write(key: _keyStorageKey, value: base64Encode(bytes));
      _key = Key(bytes);
    }

    _initialized = true;
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Encrypts [plainText] with AES-256-CBC and a fresh random IV.
  ///
  /// Returns a single opaque string: `"<ivBase64>:<cipherBase64>"`.
  /// The IV is never reused — one random IV is generated per call.
  static String encrypt(String plainText) {
    _assertReady();
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  /// Decrypts a value previously produced by [encrypt].
  ///
  /// Throws [FormatException] if the string was not created by this service.
  static String decrypt(String encryptedText) {
    _assertReady();
    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw const FormatException(
        'EncryptionService: invalid ciphertext — expected "<iv>:<cipher>".',
      );
    }
    final iv = IV(base64Decode(parts[0]));
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    return encrypter.decrypt64(parts[1], iv: iv);
  }

  // ─── Internal helpers ──────────────────────────────────────────────────────

  static Uint8List _secureRandomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }

  static void _assertReady() {
    if (!_initialized) {
      throw StateError(
        'EncryptionService.initialize() must be called before first use.',
      );
    }
  }
}
