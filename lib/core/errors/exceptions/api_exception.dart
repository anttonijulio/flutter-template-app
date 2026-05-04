import 'package:dio/dio.dart';
import 'package:template_app/core/errors/app_error.dart';
import 'package:template_app/core/constants/status_error_code.dart';
import 'package:template_app/core/errors/exceptions/app_exception.dart';
import 'package:template_app/core/utilities/logger.dart';

class ApiException extends AppException {
  final DioExceptionType? exceptionType;

  ApiException({
    required super.error,
    super.original,
    super.stackTrace,
    super.statusCode,
    super.errorCode,
    this.exceptionType,
  }) {
    Log.e(
      error.message,
      label: 'ApiException',
      error: original,
      stackTrace: stackTrace,
    );
  }

  factory ApiException.unknown([Object? error, StackTrace? stackTrace]) {
    return ApiException(
      error: AppError(
        title: 'Terjadi Gangguan',
        message:
            'Kami mengalami kendala saat terhubung ke layanan. Silakan coba lagi dalam beberapa saat.',
        code: API_UNKNOWN_ERROR_CODE,
      ),
      statusCode: UNEXPECTED_STATUS_CODE,
      errorCode: API_UNKNOWN_ERROR_CODE,
      original: error,
      stackTrace: stackTrace,
    );
  }
}
