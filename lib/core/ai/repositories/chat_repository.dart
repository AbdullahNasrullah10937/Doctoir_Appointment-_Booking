import '../models/chat_message_model.dart';
import '../services/ai_service.dart';

// Design Decision: The repository pattern wraps [AiService] with a typed API
// surface — callers use [ChatMessageModel] instead of raw Maps, satisfying the
// academic requirement while keeping the underlying service loosely coupled.
//
// [ChatRepository] is the entry point for any feature that wants to send a
// chat message and receive the complete parsed response string.
class ChatRepository {
  ChatRepository({AiService? service})
      : _service = service ?? AiService();

  final AiService _service;

  /// Sends [messages] to the AI provider and returns the complete response text.
  ///
  /// Internally accumulates the streaming deltas from [AiService.streamChat]
  /// so callers that need a single `Future<String>` can use this method.
  /// For progressive streaming UI, use [AiService.streamChat] directly.
  ///
  /// Throws an [AiException] subclass on unrecoverable errors.
  Future<String> sendMessage(List<ChatMessageModel> messages) async {
    // Convert typed models to the Map format expected by providers
    final raw = messages
        .map((m) => m.toJson())
        .toList();

    final buffer = StringBuffer();
    await for (final delta in _service.streamChat(raw)) {
      buffer.write(delta);
    }
    return buffer.toString();
  }
}
