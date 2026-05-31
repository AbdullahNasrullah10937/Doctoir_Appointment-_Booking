import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/ai_config.dart';
import '../config/ai_prompts.dart';
import '../network/api_client.dart';
import 'ai_provider.dart';

/// Design Decision: OpenAI is the primary provider because GPT-4.5/5 offers
/// superior reasoning, structured JSON reliability, and context retention —
/// qualities that matter most for a healthcare assistant and symptom triage
/// where accuracy and instruction-following are safety-critical.
class OpenAiProvider implements AiProvider {
  OpenAiProvider() {
    _dio = ApiClient.create(
      baseUrl: AiConfig.openAiBaseUrl,
      apiKey: AiConfig.openAiKey,
    );
  }

  late final Dio _dio;

  @override
  String get providerName => 'OpenAI';

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
          'model': AiConfig.openAiChatModel,
          'messages': fullMessages,
          'stream': true,
          'max_completion_tokens': 1024,
          // Note: temperature omitted — GPT-5.x and o-series models reject it
        },
        options: Options(responseType: ResponseType.stream),
      );

      yield* _parseSseStream(response.data!.stream);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Parses SSE line-by-line from the streaming response body.
  ///
  /// Design Decision: We decode bytes manually via utf8.decode() instead of
  /// byteStream.transform(utf8.decoder) because Dio delivers Stream of Uint8List
  /// at runtime. Dart's invariant generics reject Uint8List where List-of-int is
  /// expected in the StreamTransformer type, causing a cast failure despite
  /// Uint8List being a List-of-int subtype.
  Stream<String> _parseSseStream(Stream<dynamic> byteStream) async* {
    final lineBuffer = StringBuffer();

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
        } catch (_) {
          // Malformed SSE chunk — skip silently
        }
      }
    }
  }


  // ─── runSymptomTriage ────────────────────────────────────────────────────────

  @override
  Future<String> runSymptomTriage(String symptomText) async {
    return _callTriage(symptomText, stricter: false);
  }

  Future<String> runSymptomTriageStrict(String symptomText) async {
    return _callTriage(symptomText, stricter: true);
  }

  Future<String> _callTriage(String symptomText, {required bool stricter}) async {
    final systemContent = stricter
        ? '${AiPrompts.triageSystem}${AiPrompts.triageStricterRetry}'
        : AiPrompts.triageSystem;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: <String, dynamic>{
          'model': AiConfig.openAiTriageModel,
          'messages': <Map<String, String>>[
            <String, String>{'role': 'system', 'content': systemContent},
            <String, String>{'role': 'user', 'content': symptomText},
          ],
          // JSON mode — forces valid JSON output
          'response_format': <String, String>{'type': 'json_object'},
          'max_completion_tokens': 1024,
          // Note: temperature omitted — GPT-5.x and o-series models reject it
        },
      );

      final data = response.data;
      if (data == null) throw const FormatException('Empty triage response');

      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw const FormatException('No choices in triage response');
      }

      final content = (choices[0]['message'] as Map<String, dynamic>)['content'] as String?;
      return content ?? _triageFallbackJson('No content in response');
    } on DioException catch (e) {
      debugPrint('[OpenAiProvider] triage error: ${e.message}');
      throw mapDioException(e);
    }
  }

  String _triageFallbackJson(String reason) => jsonEncode(<String, dynamic>{
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
