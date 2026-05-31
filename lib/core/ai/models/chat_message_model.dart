/// Design Decision: A typed model for the API wire format prevents the
/// stringly-typed Map<String,String> anti-pattern and gives compile-time
/// safety when constructing OpenAI-compatible message payloads.

/// Represents a single chat message in OpenAI-compatible format.
/// Used as the wire format sent to both OpenAI and Groq providers.
class ChatMessageModel {
  const ChatMessageModel({
    required this.role,
    required this.content,
  });

  /// OpenAI role: 'system' | 'user' | 'assistant'
  final String role;

  /// The message text content.
  final String content;

  // ─── Serialisation ──────────────────────────────────────────────────────────
  // Note: fromJson/toJson are hand-written for clarity and zero build_runner
  // dependency — fully null-safe and type-checked.

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, String> toJson() => <String, String>{
        'role': role,
        'content': content,
      };

  // ─── Convenience constructors ───────────────────────────────────────────────
  factory ChatMessageModel.user(String content) =>
      ChatMessageModel(role: 'user', content: content);

  factory ChatMessageModel.assistant(String content) =>
      ChatMessageModel(role: 'assistant', content: content);

  factory ChatMessageModel.system(String content) =>
      ChatMessageModel(role: 'system', content: content);

  /// Converts a legacy Map<String,String> (used in existing app_state code)
  /// to a typed [ChatMessageModel] for repository-layer consumers.
  factory ChatMessageModel.fromMap(Map<String, String> map) =>
      ChatMessageModel(role: map['role'] ?? 'user', content: map['content'] ?? '');

  @override
  String toString() => 'ChatMessageModel(role: $role, content: ${content.substring(0, content.length.clamp(0, 40))}...)';
}
