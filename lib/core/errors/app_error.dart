import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:template_app/core/constants/status_error_code.dart';
import 'package:template_app/core/errors/exceptions/api_exception.dart';
import 'package:template_app/core/errors/exceptions/network_exception.dart';
import 'package:template_app/core/errors/exceptions/parsing_exception.dart';

class AppError extends Equatable {
  final String message;
  final String title;
  final String? code; // e.g. 'ERR_NO_INTERNET', 'ERR_UNAUTHORIZED'

  const AppError({
    required this.message,
    this.title = "Terjadi Kesalahan",
    this.code,
  });

  @override
  List<Object?> get props => [message, title, code];

  AppError copyWith({String? message, String? title, String? code}) {
    return AppError(
      message: message ?? this.message,
      title: title ?? this.title,
      code: code ?? this.code,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'message': message, 'title': title, 'code': code};
  }

  factory AppError.fromMap(Map<String, dynamic> map) {
    return AppError(
      message: map['message'] ?? "",
      title: map['title'],
      code: map['code'],
    );
  }

  factory AppError.fromException(Object e) {
    if (e is ApiException) return e.error;
    if (e is ParsingException) return e.error;
    if (e is NetworkException) return e.error;
    if (e is FormatException) {
      return AppError(
        title: 'Gagal Memuat Data',
        message:
            'Kami mengalami kendala saat memproses data. Silakan coba lagi dalam beberapa saat.',
        code: DATA_PARSING_ERROR_CODE,
      );
    }
    if (e is TimeoutException) {
      return AppError(
        title: 'Proses Terlalu Lama',
        message:
            'Operasi memakan waktu lebih lama dari yang diharapkan. Silakan coba lagi.',
        code: PROCESS_TIMEOUT_ERROR_CODE,
      );
    }
    return AppError(
      title: "Terjadi Kesalahan",
      message:
          "Terjadi kesalahan yang tidak terduga. Coba lagi dalam beberapa saat.",
      code: UNEXPECTED_ERROR_CODE,
    );
  }
}
