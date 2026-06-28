import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class LoggingInterceptor extends Interceptor {
  final _log = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.d('[HTTP] ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log.d('[HTTP] ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.e('[HTTP] ERROR ${err.requestOptions.uri}: ${err.message}');
    handler.next(err);
  }
}
