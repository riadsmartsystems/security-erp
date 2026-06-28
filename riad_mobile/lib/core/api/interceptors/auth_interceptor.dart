import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FL0 stub: FL1 реалізує JWT attach + авто-refresh при 401
class AuthInterceptor extends Interceptor {
  // ignore: unused_field
  final Ref _ref;
  AuthInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // FL1: attach Authorization: Bearer <accessToken>
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // FL1: handle 401 → refresh → retry; RIAD-REFRESH-REUSE → force logout
    handler.next(err);
  }
}
