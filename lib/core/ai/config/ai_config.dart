import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration reader for the AI integration layer.
///
/// Design Decision: Loading configuration values from `.env` dynamically
/// prevents hardcoding sensitive constants and makes it extremely simple
/// to adjust model names, rate limit behaviors, and network timeouts
/// without re-compiling the application.
class AiConfig {
  AiConfig._(); // Static-only class

  // ─── API Keys ──────────────────────────────────────────────────────────────

  /// Seed OpenAI API key from the environment.
  static String get openAiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  /// Seed Groq API key from the environment.
  static String get groqKey => dotenv.env['GROQ_API_KEY'] ?? '';

  // ─── Base URLs ─────────────────────────────────────────────────────────────

  /// Base endpoint URL for OpenAI requests.
  static const String openAiBaseUrl = 'https://api.openai.com/v1';

  /// Base endpoint URL for Groq requests.
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';

  // ─── Model Configurations ──────────────────────────────────────────────────

  /// The main chat model for conversational assistant turns on OpenAI (Primary).
  static const String openAiChatModel = 'gpt-5.5';

  /// The symptom triage analysis model on OpenAI (Primary).
  static const String openAiTriageModel = 'gpt-5.5';

  /// The chat model on Groq (Fallback).
  static const String groqChatModel = 'llama-3.3-70b-versatile';

  /// The symptom triage analysis model on Groq (Fallback).
  static const String groqTriageModel = 'llama-3.3-70b-versatile';

  // ─── Secure Storage Keys ───────────────────────────────────────────────────

  /// Storage key name for OpenAI API Key.
  static const String secureKeyOpenAi = 'qurexa_openai_api_key';

  /// Storage key name for Groq API Key.
  static const String secureKeyGroq = 'qurexa_groq_api_key';

  // ─── Network Settings ──────────────────────────────────────────────────────

  /// Maximum attempts for Dio retry client before throwing Exception.
  static const int primaryMaxRetries = 1;

  /// Connection timeout threshold.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Receive timeout threshold.
  static const Duration receiveTimeout = Duration(seconds: 15);

  // ─── Triage Schema Validation ──────────────────────────────────────────────

  /// List of absolute required JSON keys that the symptom triage parser expects.
  /// Used by [_isValidTriageJson] in [AiService] to prevent partial UI parsing.
  static const List<String> triageRequiredFields = <String>[
    'summary',
    'urgency',
    'rationalization',
    'suggested_specialties',
    'follow_up_questions',
    'cautious_conditions',
    'confidence_score',
    'disclaimer',
    'red_flags',
    'lifestyle_advice',
  ];
}
