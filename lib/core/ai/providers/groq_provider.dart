import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/ai_config.dart';
import '../config/ai_prompts.dart';
import '../network/api_client.dart';
import '../../logging/logging_service.dart';
import 'ai_provider.dart';

/// Design Decision: The Groq provider acts as a high-speed emergency fallback
/// because Llama-3.3-70b on Groq's LPU delivers sub-100ms TTFT (time-to-first-
/// token), ensuring near-zero downtime when OpenAI is temporarily unavailable.
class GroqProvider implements AiProvider {
  GroqProvider() {
    _dio = ApiClient.create(
      baseUrl: AiConfig.groqBaseUrl,
      apiKey: AiConfig.groqKey,
      maxRetries: 0, // Groq is already a fallback — no nested retries
    );
  }

  late final Dio _dio;

  @override
  String get providerName => 'Groq';

  // Prompts are sourced from AiPrompts — single source of truth for all providers.


  // ─── streamChat ──────────────────────────────────────────────────────────────

  @override
  Stream<String> streamChat(List<Map<String, String>> messages) async* {
    final fullMessages = <Map<String, String>>[
      <String, String>{'role': 'system', 'content': AiPrompts.chatSystem},
      ...messages,
    ];

    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/completions',
        data: <String, dynamic>{
          'model': AiConfig.groqChatModel,
          'messages': fullMessages,
          'stream': true,
          'max_tokens': 1024,
          'temperature': 0.7,
        },
        options: Options(responseType: ResponseType.stream),
      );

      final lineBuffer = StringBuffer();
      final byteStream = response.data!.stream;
      await for (final rawBytes in byteStream) {
        final chunk = rawBytes is String
            ? rawBytes
            : utf8.decode(rawBytes as List<int>, allowMalformed: true);
        lineBuffer.write(chunk);
        final raw = lineBuffer.toString();
        final lines = raw.split('\n');
        lineBuffer
          ..clear()
          ..write(lines.last);

        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isEmpty || !line.startsWith('data:')) continue;
          final data = line.substring(5).trim();
          if (data == '[DONE]') return;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) yield content;
            }
          } catch (_) {}
        }
      }
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ─── runSymptomTriage ────────────────────────────────────────────────────────

  @override
  Future<String> runSymptomTriage(String symptomText) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: <String, dynamic>{
          'model': AiConfig.groqTriageModel,
          'messages': <Map<String, String>>[
            <String, String>{'role': 'system', 'content': AiPrompts.triageSystem},
            <String, String>{'role': 'user', 'content': symptomText},
          ],
          'response_format': <String, String>{'type': 'json_object'},
          'max_tokens': 1024,
          'temperature': 0.3,
        },
      );

      final choices = response.data?['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw const FormatException('No choices in Groq triage response');
      }
      final content =
          (choices[0]['message'] as Map<String, dynamic>)['content'] as String?;
      return content ?? _fallbackJson('No content');
    } on DioException catch (e) {
      LoggingService.error('GroqProvider triage error: ${e.message}', error: e);
      throw mapDioException(e);
    }
  }

  String _fallbackJson(String reason) => jsonEncode(<String, dynamic>{
        'summary': 'Could not complete triage assessment.',
        'urgency': 'URGENT',
        'rationalization': reason,
        'suggested_specialties': <String>['General Physician'],
        'follow_up_questions': <String>['Please try describing your symptoms again.'],
        'cautious_conditions': <String>['Connection Error'],
        'confidence_score': '0',
        'disclaimer': 'This triage assessment is AI-generated and does not constitute a medical diagnosis.',
        'red_flags': <String>[],
        'lifestyle_advice': 'Seek direct medical consultation.',
      });
}
