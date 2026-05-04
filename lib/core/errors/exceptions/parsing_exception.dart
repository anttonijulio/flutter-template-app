import 'package:template_app/core/constants/status_error_code.dart';
import 'package:template_app/core/errors/exceptions/app_exception.dart';
import 'package:template_app/core/utilities/logger.dart';

import '../app_error.dart';

class ParsingException extends AppException {
  static const _defaultError = AppError(
    title: 'Gagal Memuat Data',
    message:
        'Kami mengalami kendala saat memproses data. Silakan coba lagi dalam beberapa saat.',
    code: DATA_PARSING_ERROR_CODE,
  );

  ParsingException({
    super.error = _defaultError,
    super.original,
    super.stackTrace,
  }) {
    Log.e(
      error.message,
      label: 'ParsingException',
      error: original,
      stackTrace: stackTrace,
    );
  }
}
