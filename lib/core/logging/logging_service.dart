import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

enum LogLevel { debug, info, warning, error }

class LoggingService {
  static File? _logFile;
  static bool _initialized = false;
  static const int _maxFileSizeBytes = 2 * 1024 * 1024; // 2MB

  /// Initialise the logging service. Detects directories and prepares log persistence.
  static Future<void> initialize() async {
    if (_initialized) return;

    if (!kIsWeb) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final logDir = Directory('${directory.path}/logs');
        if (!await logDir.exists()) {
          await logDir.create(recursive: true);
        }
        _logFile = File('${logDir.path}/app_logs.txt');
        await _checkAndRotateLogs();
        _initialized = true;
        info('LoggingService initialized. Local logs saved at: ${_logFile!.path}');
      } catch (e) {
        debugPrint('[LoggingService] Failed to initialize file logging: $e');
      }
    } else {
      _initialized = true;
      info('LoggingService initialized (Web platform, console only).');
    }
  }

  /// Check size of the log file and rotate if it exceeds max size.
  static Future<void> _checkAndRotateLogs() async {
    if (_logFile == null) return;
    try {
      if (await _logFile!.exists()) {
        final size = await _logFile!.length();
        if (size > _maxFileSizeBytes) {
          final oldFile = File('${_logFile!.path}.old');
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
          await _logFile!.rename(oldFile.path);
          // Create new blank log file
          await _logFile!.create();
          info('Log file exceeded limit, rotated logs.');
        }
      } else {
        await _logFile!.create();
      }
    } catch (e) {
      debugPrint('[LoggingService] Error rotating logs: $e');
    }
  }

  /// Print log to console, write to local file, and send to Firebase Crashlytics.
  static void _log(LogLevel level, String message, {Object? error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final levelName = level.name.toUpperCase();
    final formattedConsole = '[$levelName] [$timestamp] $message';
    final formattedFile = '[$levelName] [$timestamp] $message${error != null ? '\nError: $error' : ''}${stackTrace != null ? '\nStackTrace:\n$stackTrace' : ''}\n';

    // 1. Output to local console using debugPrint to respect IDE formats
    debugPrint(formattedConsole);
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('StackTrace:\n$stackTrace');
    }

    // 2. Append to local file asynchronously if on native platforms
    if (!kIsWeb && _logFile != null) {
      _writeLogToFile(formattedFile);
    }

    // 3. Send to Firebase Crashlytics if initialized and available
    try {
      if (!kIsWeb) {
        // Crashlytics logs (breadcrumbs)
        FirebaseCrashlytics.instance.log(formattedConsole);

        // Record error details for high severity logs
        if (level == LogLevel.error) {
          FirebaseCrashlytics.instance.recordError(
            error ?? message,
            stackTrace,
            reason: message,
            fatal: false,
          );
        } else if (level == LogLevel.warning && error != null) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            reason: message,
            fatal: false,
          );
        }
      }
    } catch (e) {
      // Avoid crash if Crashlytics isn't fully configured/accessible in this environment
      debugPrint('[LoggingService] Crashlytics logging failed: $e');
    }
  }

  static Future<void> _writeLogToFile(String logContent) async {
    try {
      if (_logFile != null) {
        await _logFile!.writeAsString(logContent, mode: FileMode.append, flush: true);
        // Periodic check to ensure log rotation doesn't let logs run away
        final size = await _logFile!.length();
        if (size > _maxFileSizeBytes) {
          await _checkAndRotateLogs();
        }
      }
    } catch (e) {
      debugPrint('[LoggingService] Write log to file failed: $e');
    }
  }

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }
}
