import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/envelope_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

// API base URL: встановлюється через --dart-define=API_BASE_URL=...
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.riad.fun/api/v2',
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    contentType: Headers.jsonContentType,
  ));

  dio.interceptors.addAll([
    LoggingInterceptor(),
    AuthInterceptor(ref),
    EnvelopeInterceptor(),
  ]);

  return dio;
});
