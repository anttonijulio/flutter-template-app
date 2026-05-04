import 'package:template_app/core/errors/app_error.dart';
import 'package:template_app/core/errors/exceptions/app_exception.dart';
import 'package:template_app/core/utilities/logger.dart';

import '../../constants/status_error_code.dart';

class NetworkException extends AppException {
  static const _defaultError = AppError(
    title: 'Tidak Ada Koneksi',
    message: 'Periksa koneksi internet Anda dan coba lagi.',
    code: OFFLINE_ERROR_CODE,
  );

  NetworkException({super.error = _defaultError}) {
    Log.e(
      error.message,
      label: 'NetworkException',
      error: original,
      stackTrace: stackTrace,
    );
  }
}
