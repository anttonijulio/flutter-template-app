import 'package:equatable/equatable.dart';
import 'package:template_app/core/constants/status_error_code.dart';

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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'message': message, 'title': title, 'code': code};
  }

  factory AppError.fromJson(Map<String, dynamic> map) {
    return AppError(
      message: map['message'] ?? "",
      title: map['title'],
      code: map['code'],
    );
  }

  factory AppError.fromException(Object e) {
    return AppError(
      title: "Terjadi Kesalahan",
      message:
          "Terjadi kesalahan yang tidak terduga. Coba lagi dalam beberapa saat.",
      code: UNEXPECTED_ERROR_CODE,
    );
  }
}
