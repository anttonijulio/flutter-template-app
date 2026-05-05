import 'package:equatable/equatable.dart';

// {
//     "status": 200,
//     "error": false,
//     "message": "Successfully",
//     "data": [] T
//     "total": 0, //! pagination
//     "per_page": 0, //! pagination
//     "prev_page": 1, //! pagination
//     "next_page": 2, //! pagination
//     "current_page": 1, //! pagination
//     "next_url": "http://localhost:6363?page=2", //! pagination
//     "prev_url": "http://localhost:6363?page=1", //! pagination
// }

class ResponseDto<T> extends Equatable {
  final dynamic status;
  final bool error;
  final String message;
  final T? data;
  final int? total;
  final int? perPage;
  final int? prevPage;
  final String? code;
  final int? nextPage;
  final int? currentPage;
  final String? nextUrl;
  final String? prevUrl;

  const ResponseDto({
    required this.status,
    required this.error,
    required this.message,
    this.total,
    this.perPage,
    this.prevPage,
    this.code,
    this.nextPage,
    this.currentPage,
    this.nextUrl,
    this.prevUrl,
    this.data,
  });

  @override
  List<Object?> get props {
    return [
      status,
      error,
      message,
      total,
      perPage,
      prevPage,
      code,
      nextPage,
      currentPage,
      nextUrl,
      prevUrl,
      data,
    ];
  }

  factory ResponseDto.fromJson(Map<String, dynamic> map) {
    return ResponseDto<T>(
      status: map['status'],
      error: map['error'],
      message: map['message'],
      total: map['total'],
      perPage: map['per_page'],
      prevPage: map['prev_page'],
      code: map['code'],
      nextPage: map['next_page'],
      currentPage: map['current_page'],
      nextUrl: map['next_url'],
      prevUrl: map['prev_url'],
      data: map['data'],
    );
  }
}
