import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';

import '../../logging/logging_service.dart';
import '../config/ai_config.dart';

// ─── HTTP Performance Monitoring Interceptor ───────────────────────────────────

class _PerformanceInterceptor extends Interceptor {
  final Map<int, HttpMetric> _metrics = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final metric = FirebasePerformance.instance.newHttpMetric(
        options.uri.toString(),
        _mapHttpMethod(options.method),
      );
      await metric.start();
      _metrics[options.hashCode] = metric;
    } catch (_) {}
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    try {
      final metric = _metrics.remove(response.requestOptions.hashCode);
      if (metric != null) {
        metric.httpResponseCode = response.statusCode;
        final responseBody = response.data;
        if (responseBody != null) {
          metric.responsePayloadSize = responseBody.toString().length;
        }
        await metric.stop();
      }
    } catch (_) {}
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      final metric = _metrics.remove(err.requestOptions.hashCode);
      if (metric != null) {
        metric.httpResponseCode = err.response?.statusCode;
        await metric.stop();
      }
    } catch (_) {}
    handler.next(err);
  }

  HttpMethod _mapHttpMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return HttpMethod.Get;
      case 'POST':
        return HttpMethod.Post;
      case 'PUT':
        return HttpMethod.Put;
      case 'DELETE':
        return HttpMethod.Delete;
      case 'PATCH':
        return HttpMethod.Patch;
      case 'HEAD':
        return HttpMethod.Head;
      case 'OPTIONS':
        return HttpMethod.Options;
      default:
        return HttpMethod.Get;
    }
  }
}

// ─── Typed AI Exceptions ───────────────────────────────────────────────────────

/// Base class for all AI-layer exceptions.
abstract class AiException implements Exception {
  const AiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'AiException($statusCode): $message';
}

/// 401 — API key missing, invalid, or revoked.
class AiAuthException extends AiException {
  const AiAuthException([super.message = 'Invalid or missing API key.'])
      : super(statusCode: 401);
}

/// 408 / connect timeout / receive timeout.
class AiTimeoutException extends AiException {
  const AiTimeoutException([super.message = 'Request timed out.'])
      : super(statusCode: 408);
}

/// 429 — Rate limit exceeded.
class AiRateLimitException extends AiException {
  const AiRateLimitException([super.message = 'Rate limit exceeded. Please wait before retrying.'])
      : super(statusCode: 429);
}

/// 5xx — Upstream server error.
class AiServerException extends AiException {
  const AiServerException([super.message = 'Server error. Please try again shortly.', int statusCode = 500])
      : super(statusCode: statusCode);
}

/// Generic / network-level failure.
class AiNetworkException extends AiException {
  const AiNetworkException([super.message = 'Network error. Check your connection.']);
}

// ─── Retry Interceptor ─────────────────────────────────────────────────────────

/// Design Decision: A custom retry interceptor gives us fine-grained control
/// over WHICH errors trigger a retry (timeout + server errors only), and HOW
/// MANY retries are attempted, fulfilling the academic requirement without
/// adding extra packages to the dependency tree.
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor({required this.dio, required this.maxRetries});

  final Dio dio;
  final int maxRetries;

  // Track retry count per request via extra map
  static const String _retryKey = '_retry_count';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final extra = Map<String, dynamic>.from(err.requestOptions.extra);
    final retries = (extra[_retryKey] as int?) ?? 0;

    final shouldRetry = retries < maxRetries && _isRetryable(err);

    if (!shouldRetry) {
      return handler.next(err);
    }

    extra[_retryKey] = retries + 1;
    LoggingService.warning('[RetryInterceptor] Retry ${extra[_retryKey]}/$maxRetries for ${err.requestOptions.path}');

    // Brief backoff before retry
    await Future<void>.delayed(const Duration(milliseconds: 500));

    try {
      final response = await dio.fetch<dynamic>(
        err.requestOptions.copyWith(extra: extra),
      );
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _isRetryable(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }
}

// ─── Logging Interceptor ───────────────────────────────────────────────────────

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    LoggingService.debug('[Dio ▶] ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    LoggingService.debug('[Dio ◀] ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    LoggingService.warning('[Dio ✗] ${err.response?.statusCode} ${err.message}');
    handler.next(err);
  }
}

// ─── Error Mapping ─────────────────────────────────────────────────────────────

/// Maps a [DioException] to a typed [AiException].
/// Logs the raw API response body so the exact provider error is always visible.
AiException mapDioException(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return const AiTimeoutException();
  }

  final status = e.response?.statusCode;

  // Always log the full response body from the provider so we can diagnose issues.
  if (e.response?.data != null) {
    LoggingService.warning('[ApiClient] HTTP $status response body: ${e.response?.data}');
  }

  if (status != null) {
    if (status == 400) {
      final body = e.response?.data?.toString() ?? '';
      return AiNetworkException('Bad request (400): $body');
    }
    if (status == 401) return const AiAuthException();
    if (status == 429) return const AiRateLimitException();
    if (status >= 500) return AiServerException('Server error $status.', status);
  }

  return AiNetworkException(e.message ?? 'Unknown network error.');
}

// ─── Client Factory ────────────────────────────────────────────────────────────

/// Design Decision: A factory method (not a singleton) creates provider-specific
/// Dio instances so OpenAI and Groq each have their own base URL and Bearer
/// token without shared mutable state between providers.
class ApiClient {
  ApiClient._();

  /// Creates a fully configured Dio client for the given [baseUrl] and [apiKey].
  ///
  /// Includes:
  /// - Bearer token injection interceptor
  /// - Response / error logging interceptor (debug only)
  /// - Retry interceptor (retries timeout + 5xx up to [maxRetries] times)
  static Dio create({
    required String baseUrl,
    required String apiKey,
    int maxRetries = AiConfig.primaryMaxRetries,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AiConfig.connectTimeout,
        receiveTimeout: AiConfig.receiveTimeout,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 1. Performance interceptor — logs HTTP metric latency to Firebase
    dio.interceptors.add(_PerformanceInterceptor());

    // 2. Auth interceptor — injects Bearer token into every request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Never hardcode keys — always injected at request time
          options.headers['Authorization'] = 'Bearer $apiKey';
          handler.next(options);
        },
      ),
    );

    // 3. Logging interceptor — debug builds only
    dio.interceptors.add(_LoggingInterceptor());

    // 4. Retry interceptor — must be added AFTER logging
    dio.interceptors.add(_RetryInterceptor(dio: dio, maxRetries: maxRetries));

    return dio;
  }
}
