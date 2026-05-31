import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/ai_config.dart';

/// Design Decision: Wrapping flutter_secure_storage behind a typed helper
/// guarantees API keys are NEVER stored as plain Dart strings in memory
/// longer than necessary and are persisted in the OS keystore, not SharedPrefs.

class SecureApiKeyStorage {
  SecureApiKeyStorage._();

  static final SecureApiKeyStorage instance = SecureApiKeyStorage._();

  // Configure with high security options on Android (encrypted shared prefs)
  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ─── OpenAI Key ────────────────────────────────────────────────────────────

  /// Persists the OpenAI API key in the OS secure keystore.
  Future<void> saveOpenAiKey(String key) async =>
      _storage.write(key: AiConfig.secureKeyOpenAi, value: key);

  /// Reads the OpenAI API key. Returns null if not stored yet.
  Future<String?> readOpenAiKey() async =>
      _storage.read(key: AiConfig.secureKeyOpenAi);

  /// Removes the OpenAI API key (e.g., on user logout).
  Future<void> deleteOpenAiKey() async =>
      _storage.delete(key: AiConfig.secureKeyOpenAi);

  // ─── Groq Key ──────────────────────────────────────────────────────────────

  Future<void> saveGroqKey(String key) async =>
      _storage.write(key: AiConfig.secureKeyGroq, value: key);

  Future<String?> readGroqKey() async =>
      _storage.read(key: AiConfig.secureKeyGroq);

  Future<void> deleteGroqKey() async =>
      _storage.delete(key: AiConfig.secureKeyGroq);

  // ─── Delete All ─────────────────────────────────────────────────────────────

  /// Clears all AI keys from secure storage (call on full user logout).
  Future<void> deleteAll() async {
    await Future.wait(<Future<void>>[
      deleteOpenAiKey(),
      deleteGroqKey(),
    ]);
  }

  // ─── Seed from .env (first-run migration) ──────────────────────────────────

  /// On first run, migrates keys from dotenv into secure storage so subsequent
  /// reads come from the OS keystore rather than the bundled asset file.
  ///
  /// Call this once during app bootstrap BEFORE accessing provider keys.
  Future<void> seedFromEnvIfAbsent() async {
    final existing = await readOpenAiKey();
    if (existing == null || existing.isEmpty) {
      final envKey = AiConfig.openAiKey;
      if (envKey.isNotEmpty && envKey != 'your_openai_api_key_here') {
        await saveOpenAiKey(envKey);
      }
    }

    final existingGroq = await readGroqKey();
    if (existingGroq == null || existingGroq.isEmpty) {
      final envKey = AiConfig.groqKey;
      if (envKey.isNotEmpty) {
        await saveGroqKey(envKey);
      }
    }
  }
}
