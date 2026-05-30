import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service interfacing with Groq's OpenAI-compatible streaming API.
///
/// Model: llama-3.3-70b-versatile
/// Endpoint: https://api.groq.com/openai/v1/chat/completions
///
/// Conversation history is maintained per session in OpenAI message format.
/// Streaming is implemented via Server-Sent Events (SSE) over HTTP.
class GroqService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  late final String _apiKey;

  GroqService() {
    String apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      apiKey =
          const String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
    }
    _apiKey = (apiKey.isNotEmpty && apiKey != 'YOUR_GROQ_API_KEY_HERE')
        ? apiKey
        : 'NO_KEY_PROVIDED';
  }

  bool get isConfigured => _apiKey != 'NO_KEY_PROVIDED';

  // ---------------------------------------------------------------------------
  // System prompt defining the Qurexa AI Health Assistant personality
  // ---------------------------------------------------------------------------
  static const String _systemPrompt =
      'You are the Qurexa AI Health Assistant, a professional, highly '
      'compassionate, and legally responsible virtual clinical guide. '
      'Your purpose is to educate patients, answer general medical questions, '
      'and assist in navigating healthcare options. '
      'You are NOT a doctor, and you CANNOT diagnose or prescribe.\n\n'
      'MULTILINGUAL & CONTEXTUAL FLUENCY:\n'
      '1. You operate in Pakistan (Lahore/Faisalabad context). Patients will '
      'query you in English, Urdu (in Arabic script), Roman Urdu '
      '(e.g., "sir me dard hai", "fever ho raha hai"), or mixed English-Urdu '
      '(Hinglish/Urdish). Always respond in the same language and script style '
      'the patient used. Keep Roman Urdu simple, supportive, and warm.\n'
      '2. If Roman Urdu is used, respond in friendly, simple Roman Urdu, '
      'avoiding overly formal English translations unless requested.\n\n'
      'CLINICAL BOUNDARIES & COMPLIANCE RULES:\n'
      '1. DIAGNOSIS PROHIBITION: Never say "You have X." Instead say: '
      '"These symptoms can occur in several conditions, such as A or B. '
      'A real clinical evaluation is necessary."\n'
      '2. PRESCRIPTION PROHIBITION: Never prescribe medicines, change '
      'existing medication dosages, or recommend custom pharmacological '
      'treatments.\n'
      '3. CONVERSATIONAL TONE: Keep your tone warm, simple, and professional. '
      'Avoid dense medical jargon. Keep answers concise (under 150 words per '
      'turn).\n'
      '4. DOCTOR NAVIGATION: Always encourage finding a specialist.\n'
      '5. SAFETY HARNESS: If the user inputs acute emergency symptoms '
      '(chest pain, severe breathing difficulty, signs of stroke, poisoning), '
      'immediately warn them it is a critical medical emergency and direct them '
      'to emergency services.';

  // ---------------------------------------------------------------------------
  // Streaming chat response via Groq SSE
  // ---------------------------------------------------------------------------

  /// Streams the assistant response token by token.
  ///
  /// [messages] is the full conversation history in OpenAI format:
  /// ```dart
  /// [{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}]
  /// ```
  /// Each yielded [String] is an incremental text delta (not cumulative).
  Stream<String> streamChatResponse(
    List<Map<String, String>> messages,
  ) async* {
    if (!isConfigured) {
      yield 'Qurexa AI is not configured. Please add your GROQ_API_KEY to the .env file and restart the app.';
      return;
    }

    // Build full message list with system instruction prepended
    final fullMessages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      ...messages,
    ];

    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll(<String, String>{
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });
      request.body = jsonEncode(<String, dynamic>{
        'model': _model,
        'messages': fullMessages,
        'stream': true,
        'max_tokens': 1024,
        'temperature': 0.7,
      });

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        debugPrint('GroqService HTTP ${response.statusCode}: $errorBody');
        yield _friendlyError(response.statusCode);
        return;
      }

      // Parse SSE stream line by line
      final lineBuffer = StringBuffer();
      await for (final chunk
          in response.stream.transform(utf8.decoder)) {
        lineBuffer.write(chunk);
        final raw = lineBuffer.toString();
        final lines = raw.split('\n');

        // Keep the last potentially incomplete line in buffer
        lineBuffer.clear();
        lineBuffer.write(lines.last);

        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isEmpty || !line.startsWith('data:')) continue;

          final data = line.substring(5).trim();
          if (data == '[DONE]') return;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final delta =
                  choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            }
          } catch (_) {
            // Malformed SSE chunk – skip silently
          }
        }
      }
    } catch (e) {
      debugPrint('GroqService exception: $e');
      yield 'I\'m having trouble connecting right now. '
          'Please check your internet connection and try again.';
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Human-readable error messages
  // ---------------------------------------------------------------------------
  String _friendlyError(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Authentication failed. Please verify your GROQ_API_KEY in the .env file.';
      case 429:
        return 'Too many requests at the moment. Please wait a few seconds and try again.';
      case 503:
        return 'The Qurexa AI service is temporarily unavailable. Please try again shortly.';
      default:
        return 'Something went wrong (code $statusCode). Please try again.';
    }
  }

  // ---------------------------------------------------------------------------
  // Symptom triage – Groq forced JSON mode
  // ---------------------------------------------------------------------------

  /// System prompt for the triage engine.
  /// Explicitly instructs the model to respond ONLY with a JSON object —
  /// required when using Groq's response_format: json_object mode.
  static const String _triageSystemPrompt =
      'You are the Qurexa AI Symptom Triage Engine. '
      'Your role is to perform structured, cautious, and high-safety '
      'pre-consultation assessments. You must parse patient symptoms, '
      'classify urgency, recommend specialties, and prepare structured notes '
      'to share with a real doctor.\n\n'
      'MULTILINGUAL SUPPORT:\n'
      'The patient may input symptoms in English, Urdu (Arabic script), or '
      'Roman Urdu (e.g., "saans lene me masla ho raha hai"). Understand all '
      'these languages, but ALL JSON values must be in English for parsing.\n\n'
      'OUTPUT PROTOCOL:\n'
      'You MUST respond with ONLY a single, raw, valid JSON object — no '
      'markdown, no backticks, no extra explanation outside the JSON.\n\n'
      'REQUIRED JSON SCHEMA:\n'
      '{\n'
      '  "summary": "Concise clinical bullet-point summary of reported symptoms.",\n'
      '  "urgency": "EMERGENCY" | "URGENT" | "NON_URGENT" | "SELF_CARE",\n'
      '  "rationalization": "1-2 sentences explaining why this urgency was selected.",\n'
      '  "suggested_specialties": ["Specialty1", "Specialty2"],\n'
      '  "follow_up_questions": ["Question 1", "Question 2"],\n'
      '  "cautious_conditions": ["Possible condition 1", "Possible condition 2"]\n'
      '}\n\n'
      'URGENCY GUIDELINES:\n'
      '- EMERGENCY: Crushing chest pain, severe breathing difficulty, sudden '
      'numbness, heavy bleeding, signs of stroke or poisoning.\n'
      '- URGENT: High persistent fever, acute abdominal pain, suspected fracture.\n'
      '- NON_URGENT: Mild chronic symptoms, persistent mild cough, mild rash.\n'
      '- SELF_CARE: Trivial self-limiting symptoms (mild headache, minor scratch).\n\n'
      'CAUTION RULES:\n'
      '1. Always present cautious_conditions as possibilities, NEVER diagnoses.\n'
      '2. Keep suggested_specialties aligned to real clinical fields '
      '(General Physician, Cardiologist, ENT Specialist, Dermatologist, etc.).';

  /// Evaluates [symptomText] using Groq's JSON mode.
  ///
  /// Returns a raw JSON string matching the triage schema above.
  /// Uses a regular (non-streaming) POST with `response_format: json_object`.
  Future<String> runSymptomTriage(String symptomText) async {
    if (!isConfigured) {
      return jsonEncode(<String, dynamic>{
        'summary': 'Mock: $symptomText',
        'urgency': 'NON_URGENT',
        'rationalization':
            'Qurexa AI is not configured. Add GROQ_API_KEY to your .env file.',
        'suggested_specialties': <String>['General Physician'],
        'follow_up_questions': <String>['Please configure a valid Groq API key.'],
        'cautious_conditions': <String>['Unconfigured System'],
      });
    }

    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse(_baseUrl),
        headers: <String, String>{
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'model': _model,
          'messages': <Map<String, String>>[
            {'role': 'system', 'content': _triageSystemPrompt},
            {'role': 'user', 'content': symptomText},
          ],
          // Groq JSON mode — guarantees output is a valid JSON object
          'response_format': <String, String>{'type': 'json_object'},
          'max_tokens': 1024,
          'temperature': 0.3, // Lower temp for more deterministic structured output
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('GroqService triage HTTP ${response.statusCode}: ${response.body}');
        return _triageFallback(
          'Network error ${response.statusCode}: ${_friendlyError(response.statusCode)}',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return _triageFallback('Empty response from triage engine.');
      }

      final content =
          (choices[0]['message'] as Map<String, dynamic>)['content'] as String?;
      return content ?? _triageFallback('No content in triage response.');
    } catch (e) {
      debugPrint('GroqService triage exception: $e');
      return _triageFallback('Exception during triage: $e');
    } finally {
      client.close();
    }
  }

  /// Returns a safe fallback triage JSON string when an error occurs.
  String _triageFallback(String reason) {
    return jsonEncode(<String, dynamic>{
      'summary': 'Could not complete triage assessment.',
      'urgency': 'URGENT',
      'rationalization': reason,
      'suggested_specialties': <String>['General Physician'],
      'follow_up_questions': <String>['Please try describing your symptoms again.'],
      'cautious_conditions': <String>['Connection Error'],
    });
  }
}
