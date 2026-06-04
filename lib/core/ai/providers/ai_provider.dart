// Design Decision: An abstract interface decouples all callers from provider
// implementations — adding Gemini or Claude later requires only a new class
// that implements this contract, with zero changes to AiService or AppState.

/// Contract all AI providers must implement.
///
/// [streamChat] yields incremental text deltas (not cumulative) so the UI
/// can render the response progressively — matching the SSE streaming model
/// already used throughout the app.
///
/// [runSymptomTriage] returns a raw JSON string conforming to the triage schema
/// so the existing [parseTriageResponseIsolate] in app_state can parse it.
abstract class AiProvider {
  const AiProvider();

  /// Streams the assistant response token by token.
  ///
  /// [messages] must be in OpenAI-compatible format:
  /// `[{'role': 'user'/'assistant'/'system', 'content': '...'}]`
  ///
  /// Each yielded [String] is an incremental delta — callers must accumulate.
  Stream<String> streamChat(List<Map<String, String>> messages);

  /// Evaluates [symptomText] and returns a raw JSON string matching the
  /// triage schema expected by [parseTriageResponseIsolate].
  Future<String> runSymptomTriage(String symptomText);

  /// Human-readable name for logging / debugging.
  String get providerName;
}
