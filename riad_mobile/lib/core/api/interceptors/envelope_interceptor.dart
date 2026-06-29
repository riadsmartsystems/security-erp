import 'package:dio/dio.dart';

/// Розгортає конверт {ok: bool, data: T | error: {code, message, request_id}}
/// ok=true → response.data = тіло data
/// ok=false → DioException з message = error.code
/// Якщо поле ok відсутнє (напр. /auth/*) — пропускає як є
class EnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('ok')) {
      if (body['ok'] == true) {
        response.data = body['data'];
        handler.next(response);
      } else {
        final err = body['error'] as Map<String, dynamic>? ?? {};
        handler.reject(DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: err['code']?.toString() ?? 'UNKNOWN_ERROR',
        ));
      }
    } else {
      handler.next(response);
    }
  }
}
