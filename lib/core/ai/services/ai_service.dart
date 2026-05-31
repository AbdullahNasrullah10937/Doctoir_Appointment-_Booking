import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/ai_config.dart';
import '../network/api_client.dart';
import '../providers/groq_provider.dart';
import '../providers/openai_provider.dart';

/// Design Decision: AiService owns the provider-selection logic in one place,
/// keeping both providers completely unaware of each other and leaving AppState
/// with a simple two-method API that matches the existing GroqService signatures
/// — enabling a zero-UI-change swap.
class AiService {
  AiService()
      : _openAi = OpenAiProvider(),
        _groq = GroqProvider();

  final OpenAiProvider _openAi;
  final GroqProvider _groq;

  // ─── Chat Streaming ──────────────────────────────────────────────────────────
  //
  // Flow:
  //   User Prompt
  //        ↓
  //    OpenAI GPT-4.5
  //        ↓
  //   Timeout / Error?  ──── retry once ────► Still failed?
  //        ↓ No                                      ↓ Yes
  //      Return                               Groq Fallback
  //                                                ↓
  //                                             Return

  /// Streams the AI assistant reply token by token.
  ///
  /// Primary: OpenAI (GPT-4.5 / GPT-5 when updated in [AiConfig]).
  /// Fallback: Groq (llama-3.3-70b-versatile).
  ///
  /// Returns an incremental-delta stream — each emitted [String] is a text
  /// chunk, NOT the full cumulative text. AppState accumulates via StringBuffer.
  Stream<String> streamChat(List<Map<String, String>> messages) async* {
    // Attempt OpenAI primary (the Dio retry interceptor handles 1 retry)
    try {
      await for (final delta in _openAi.streamChat(messages)) {
        yield delta;
      }
      return;
    } on AiException catch (e) {
      debugPrint('[AiService] OpenAI chat failed (${e.runtimeType}): ${e.message}. Switching to Groq fallback.');
    } catch (e) {
      debugPrint('[AiService] OpenAI chat unexpected error: $e. Switching to Groq fallback.');
    }

    // Groq fallback
    try {
      await for (final delta in _groq.streamChat(messages)) {
        yield delta;
      }
    } on AiException catch (e) {
      debugPrint('[AiService] Groq fallback chat also failed: ${e.message}');
      yield 'I\'m having trouble connecting right now. Please check your internet connection and try again.';
    } catch (e) {
      yield 'I\'m having trouble connecting right now. Please check your internet connection and try again.';
    }
  }

  // ─── Symptom Triage ──────────────────────────────────────────────────────────
  //
  // Flow:
  //   Symptoms
  //       ↓
  //   OpenAI JSON mode
  //       ↓
  //   Valid JSON?  ── No ──► Retry with stricter prompt
  //       ↓ Yes                       ↓
  //     Return             Valid JSON?  ── No ──► Groq fallback ──► Return
  //                            ↓ Yes
  //                          Return

  /// Runs the symptom triage engine and returns a raw JSON string.
  ///
  /// Validates required schema fields before returning to prevent UI crashes.
  /// Primary: OpenAI (1 retry with stricter prompt on invalid JSON).
  /// Fallback: Groq.
  Future<String> runSymptomTriage(String symptomText) async {
    // ── 1. OpenAI attempt ──────────────────────────────────────────────────
    try {
      final raw = await _openAi.runSymptomTriage(symptomText);
      if (_isValidTriageJson(raw)) return raw;

      debugPrint('[AiService] OpenAI triage JSON invalid — retrying with stricter prompt.');

      // ── 2. OpenAI retry (stricter prompt) ──────────────────────────────
      final retried = await _openAi.runSymptomTriageStrict(symptomText);
      if (_isValidTriageJson(retried)) return retried;

      debugPrint('[AiService] OpenAI triage retry still invalid — falling back to Groq.');
    } on AiException catch (e) {
      debugPrint('[AiService] OpenAI triage error: ${e.message}. Falling back to Groq.');
    } catch (e) {
      debugPrint('[AiService] OpenAI triage unexpected error: $e. Falling back to Groq.');
    }

    // ── 3. Groq fallback ───────────────────────────────────────────────────
    try {
      final groqRaw = await _groq.runSymptomTriage(symptomText);
      if (_isValidTriageJson(groqRaw)) return groqRaw;
      debugPrint('[AiService] Groq triage JSON also invalid — returning safe fallback.');
    } on AiException catch (e) {
      debugPrint('[AiService] Groq triage fallback also failed: ${e.message}');
    } catch (e) {
      debugPrint('[AiService] Groq fallback unexpected error: $e');
    }

    // ── 4. Safe UI fallback JSON ───────────────────────────────────────────
    return _safeFallbackTriageJson();
  }

  // ─── JSON Schema Validation ──────────────────────────────────────────────────

  /// Returns true only if [rawJson] parses successfully AND contains all
  /// required triage fields defined in [AiConfig.triageRequiredFields].
  ///
  /// This prevents the UI from receiving partial JSON that would cause
  /// null-dereference errors when rendering triage cards.
  bool _isValidTriageJson(String rawJson) {
    try {
      // Extract JSON object from raw text (handles extra whitespace/preamble)
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(rawJson);
      if (match == null) return false;

      final parsed = jsonDecode(match.group(0)!) as Map<String, dynamic>;

      for (final field in AiConfig.triageRequiredFields) {
        if (!parsed.containsKey(field)) {
          debugPrint('[AiService] Missing required triage field: $field');
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  String _safeFallbackTriageJson() => jsonEncode(<String, dynamic>{
        'summary': 'Could not complete triage assessment at this time.',
        'urgency': 'URGENT',
        'rationalization':
            'Both AI providers are currently unavailable. Please consult a medical practitioner directly.',
        'suggested_specialties': <String>['General Physician'],
        'follow_up_questions': <String>['Please share your symptoms in detail with your doctor.'],
        'cautious_conditions': <String>['Triage Assessment Incomplete'],
        'confidence_score': '0',
        'disclaimer': 'This triage assessment is AI-generated and does not constitute a medical diagnosis.',
        'red_flags': <String>[],
        'lifestyle_advice': 'Seek direct medical consultation.',
      });
}
