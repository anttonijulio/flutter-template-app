import 'package:dio/dio.dart';
import 'package:template_app/features/auth/notifier/auth_notifier.dart';

class AuthInterceptor extends Interceptor {
  final AuthNotifier _authNotifier;

  AuthInterceptor(this._authNotifier);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _authNotifier.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
