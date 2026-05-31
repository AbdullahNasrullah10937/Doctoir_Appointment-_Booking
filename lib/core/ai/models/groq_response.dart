/// Design Decision: Parsing the full Groq/OpenAI response into a typed model
/// isolates the fragile JSON traversal in one place — all callers receive a
/// clean [GroqResponse] instead of indexing raw dynamic maps.

/// Represents the full chat completion response from Groq / OpenAI APIs.
/// Both APIs share the same OpenAI-compatible response shape.
class GroqResponse {
  const GroqResponse({
    required this.id,
    required this.model,
    required this.replyText,
    required this.finishReason,
  });

  final String id;
  final String model;

  /// The AI-generated reply — extracted from choices[0].message.content
  final String replyText;

  /// Reason the model stopped: 'stop', 'length', 'content_filter', etc.
  final String finishReason;

  // ─── Parsing ────────────────────────────────────────────────────────────────

  /// Parses the full JSON body returned by the chat completions endpoint.
  /// Throws [FormatException] if the structure is invalid or choices is empty.
  factory GroqResponse.fromJson(Map<String, dynamic> json) {
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const FormatException('GroqResponse: choices array is missing or empty');
    }

    final first = choices[0] as Map<String, dynamic>;
    final message = first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null) {
      throw const FormatException('GroqResponse: choices[0].message.content is null');
    }

    return GroqResponse(
      id: json['id'] as String? ?? '',
      model: json['model'] as String? ?? '',
      replyText: content,
      finishReason: first['finish_reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'model': model,
        'reply_text': replyText,
        'finish_reason': finishReason,
      };

  @override
  String toString() => 'GroqResponse(model: $model, reply: ${replyText.substring(0, replyText.length.clamp(0, 60))}...)';
}
