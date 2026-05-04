import 'package:template_app/core/errors/app_error.dart';

class AppException implements Exception {
  final AppError error;
  final String? errorCode;
  final int? statusCode;
  final Object? original;
  final StackTrace? stackTrace;

  AppException({
    required this.error,
    this.errorCode,
    this.statusCode,
    this.original,
    this.stackTrace,
  });
}
