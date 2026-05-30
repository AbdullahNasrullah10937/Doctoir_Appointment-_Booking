import 'dart:developer' as dev;

/// A robust, multilingual safety guardrail that intercepts acute medical
/// emergencies locally on the device (English, Urdu, and Roman Urdu support).
///
/// Bypasses the AI model immediately to present direct emergency warning flows.
class EmergencyParser {
  EmergencyParser._();

  // Multi-lingual Regex patterns to capture emergency intentions
  static final RegExp _chestPainRegex = RegExp(
    r'(chest|heart|seena|dil|chati|cardiac).*(pain|hurt|tight|pressure|heavy|takleef|dard|pressure|douran|squeeze)',
    caseSensitive: false,
  );

  static final RegExp _breathingRegex = RegExp(
    r'(breath|saans|sans|lung).*(difficult|cant|stop|short|tangi|ruky|muskhil|heavy|ufq|band|ghutan)',
    caseSensitive: false,
  );

  static final RegExp _strokeParalysisRegex = RegExp(
    r'(stroke|paraly|face|weakness|falij|sunn|paralysis|dora|jhatkay)',
    caseSensitive: false,
  );

  static final RegExp _severeBleedingUnconsciousRegex = RegExp(
    r'(bleed|bleeding|blood|khon|khoon|unconscious|behosh|be hosh|gashi|zehar|poison|suicide|khudkushi)',
    caseSensitive: false,
  );

  static final RegExp _urduDirectRegex = RegExp(
    r'(دل کا درد|سانس بند|فالج|بے ہوش|خون بہنا|خودکشی|زہر)',
    caseSensitive: false,
  );

  /// Analyzes the input string to check if it matches a critical clinical emergency.
  ///
  /// Supports English, Urdu script, and Roman Urdu phrases (e.g. "seene me dard", "dil me takleef").
  static bool isEmergency(String input) {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return false;

    dev.log('EmergencyParser: Evaluating input safety: "$cleanInput"');

    final matchesChestPain = _chestPainRegex.hasMatch(cleanInput);
    final matchesBreathing = _breathingRegex.hasMatch(cleanInput);
    final matchesStroke = _strokeParalysisRegex.hasMatch(cleanInput);
    final matchesSevereBleeding = _severeBleedingUnconsciousRegex.hasMatch(cleanInput);
    final matchesUrduDirect = _urduDirectRegex.hasMatch(cleanInput);

    final isCrit = matchesChestPain ||
        matchesBreathing ||
        matchesStroke ||
        matchesSevereBleeding ||
        matchesUrduDirect;

    if (isCrit) {
      dev.log('EmergencyParser: ⚠️ CRITICAL EMERGENCY INTENT DETECTED');
    }

    return isCrit;
  }
}
