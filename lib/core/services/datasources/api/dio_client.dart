import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:template_app/core/errors/app_error.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:template_app/core/constants/status_error_code.dart';
import 'package:template_app/core/errors/exceptions/api_exception.dart';
import 'package:template_app/core/errors/exceptions/network_exception.dart';

typedef ReceivedProgressCallback = void Function(int received, int total);
typedef SendProgressCallback = void Function(int count, int total);

class DioClient {
  final Dio _dio;
  final Connectivity _connectivity;

  DioClient(
    String baseUrl,
    this._connectivity, {
    List<Interceptor> interceptors = const [],
    Duration connectTimeout = const Duration(seconds: 90),
    Duration receiveTimeout = const Duration(seconds: 90),
    Duration sendTimeout = const Duration(minutes: 10),
    Map<String, dynamic>? extraHeaders,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: connectTimeout,
           receiveTimeout: receiveTimeout,
           sendTimeout: sendTimeout,
           headers: extraHeaders ?? {'Accept': 'application/json'},
         ),
       ) {
    _dio.interceptors.addAll([
      ...interceptors,
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
        enabled: kDebugMode || kProfileMode,
      ),
    ]);
  }

  Dio get dio => _dio;

  Future<bool> hasInternet() {
    return _connectivity
        .checkConnectivity()
        .then((conns) {
          return conns.contains(ConnectivityResult.mobile) ||
              conns.contains(ConnectivityResult.wifi) ||
              conns.contains(ConnectivityResult.vpn);
        })
        .catchError((e, st) => false);
  }

  Future<Response<dynamic>> get({
    required String endpoint,
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    Map<String, dynamic>? queryParams,
    ReceivedProgressCallback? onReceiveProgress,
  }) async {
    try {
      if (!await hasInternet()) throw NetworkException();
      return await _dio.get(
        endpoint,
        data: data,
        options: options,
        cancelToken: cancelToken,
        queryParameters: queryParams,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e, st) {
      throw errorMapper(e, st);
    }
  }

  Future<Response<dynamic>> post({
    required String endpoint,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    SendProgressCallback? onSendProgress,
    ReceivedProgressCallback? onReceiveProgress,
  }) async {
    try {
      if (!await hasInternet()) throw NetworkException();
      return await _dio.post(
        endpoint,
        data: data,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e, st) {
      throw errorMapper(e, st);
    }
  }

  Future<Response<dynamic>> put({
    required String endpoint,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    SendProgressCallback? onSendProgress,
    ReceivedProgressCallback? onReceiveProgress,
  }) async {
    try {
      if (!await hasInternet()) throw NetworkException();
      return await _dio.put(
        endpoint,
        data: data,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e, st) {
      throw errorMapper(e, st);
    }
  }

  Future<Response<dynamic>> delete({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Object? data,
    Options? options,
  }) async {
    try {
      if (!await hasInternet()) throw NetworkException();
      return await _dio.delete(
        endpoint,
        cancelToken: cancelToken,
        data: data,
        options: options,
        queryParameters: queryParameters,
      );
    } catch (e, st) {
      throw errorMapper(e, st);
    }
  }

  ApiException errorMapper(Object error, dynamic stackTrace) {
    if (error is DioException) {
      final type = error.type;
      final statusCode = error.response?.statusCode;
      return switch (type) {
        .connectionTimeout => ApiException(
          error: AppError(
            title: "Koneksi Timeout",
            message:
                "Koneksi ke server memakan waktu terlalu lama. Periksa jaringan Anda dan coba lagi.",
            code: API_CONNECTION_TIMEOUT_ERROR_CODE,
          ),
          exceptionType: type,
          errorCode: API_CONNECTION_TIMEOUT_ERROR_CODE,
          original: error,
          stackTrace: stackTrace,
          statusCode: statusCode,
        ),
        .sendTimeout => ApiException(
          error: AppError(
            title: "Gagal Mengirim Data",
            message:
                "Pengiriman data ke server memakan waktu terlalu lama. Periksa jaringan Anda dan coba lagi.",
            code: API_SEND_TIMEOUT_ERROR_CODE,
          ),
          exceptionType: type,
          errorCode: API_SEND_TIMEOUT_ERROR_CODE,
          original: error,
          stackTrace: stackTrace,
          statusCode: statusCode,
        ),
        .receiveTimeout => ApiException(
          error: AppError(
            title: "Gagal Menerima Respons",
            message:
                "Server tidak merespons dalam waktu yang ditentukan. Coba lagi beberapa saat.",
            code: API_RECEIVE_TIMEOUT_ERROR_CODE,
          ),
          exceptionType: type,
          errorCode: API_RECEIVE_TIMEOUT_ERROR_CODE,
          original: error,
          stackTrace: stackTrace,
          statusCode: statusCode,
        ),
        .badCertificate => ApiException(
          error: AppError(
            title: "Koneksi Tidak Aman",
            message:
                "Tidak dapat terhubung karena sertifikat keamanan server tidak valid. Hubungi tim dukungan jika masalah berlanjut.",
            code: API_BAD_CERTIFICATE_ERROR_CODE,
          ),
          exceptionType: type,
          errorCode: API_BAD_CERTIFICATE_ERROR_CODE,
          original: error,
          stackTrace: stackTrace,
          statusCode: statusCode,
        ),
        .badResponse => _mapHttpStatusCode(
          error: error,
          stackTrace: stackTrace,
          statusCode: statusCode,
          type: type,
        ),
        .cancel => ApiException(
          error: AppError(
            title: "Permintaan Dibatalkan",
            message: "Permintaan telah dibatalkan. Silakan coba lagi.",
            code: API_CANCEL_REQUEST_ERROR_CODE,
          ),
          exceptionType: type,
          errorCode: API_CANCEL_REQUEST_ERROR_CODE,
          original: error,
          stackTrace: stackTrace,
          statusCode: statusCode,
        ),
        .connectionError => ApiException(
          error: AppError(
            title: "Gagal Terhubung",
            message:
                "Tidak dapat terhubung ke server. Pastikan perangkat Anda terhubung ke internet.",
            code: API_CONNECTION_ERROR_CODE,
          ),
          exceptionType: type,
          errorCode: API_CONNECTION_ERROR_CODE,
          original: error,
          stackTrace: stackTrace,
          statusCode: statusCode,
        ),
        .unknown => ApiException(
          error: AppError(
            title: "Terjadi Kesalahan",
            message:
                "Terjadi kesalahan yang tidak diketahui. Coba lagi atau hubungi tim dukungan jika masalah berlanjut.",
            code: API_UNKNOWN_ERROR_CODE,
          ),
          exceptionType: type,
          errorCode: API_UNKNOWN_ERROR_CODE,
          original: error,
          stackTrace: stackTrace,
          statusCode: statusCode,
        ),
      };
    } else if (error is NetworkException) {
      return ApiException(
        error: error.error,
        errorCode: error.errorCode,
        original: error,
        stackTrace: stackTrace,
        statusCode: error.statusCode,
      );
    }

    return ApiException.unknown(error, stackTrace);
  }

  ApiException _mapHttpStatusCode({
    required DioException error,
    required dynamic stackTrace,
    required int? statusCode,
    required DioExceptionType type,
  }) {
    final serverMessage = _extractMessageFromBody(error.response?.data);
    return switch (statusCode) {
      400 => ApiException(
        error: AppError(
          message: serverMessage,
          code: API_BAD_REQUEST_ERROR_CODE,
        ),
        exceptionType: type,
        errorCode: API_BAD_REQUEST_ERROR_CODE,
        original: error,
        stackTrace: stackTrace,
        statusCode: statusCode,
      ),
      401 => ApiException(
        error: AppError(
          title: 'Sesi Berakhir',
          message: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
          code: API_UNAUTHORIZED_ERROR_CODE,
        ),
        exceptionType: type,
        errorCode: API_UNAUTHORIZED_ERROR_CODE,
        original: error,
        stackTrace: stackTrace,
        statusCode: statusCode,
      ),
      403 => ApiException(
        error: AppError(
          title: 'Akses Ditolak',
          message: 'Anda tidak memiliki izin untuk melakukan tindakan ini.',
          code: API_FORBIDDEN_ERROR_CODE,
        ),
        exceptionType: type,
        errorCode: API_FORBIDDEN_ERROR_CODE,
        original: error,
        stackTrace: stackTrace,
        statusCode: statusCode,
      ),
      404 => ApiException(
        error: AppError(
          title: 'Data Tidak Ditemukan',
          message: serverMessage,
          code: API_NOT_FOUND_ERROR_CODE,
        ),
        exceptionType: type,
        errorCode: API_NOT_FOUND_ERROR_CODE,
        original: error,
        stackTrace: stackTrace,
        statusCode: statusCode,
      ),
      409 => ApiException(
        error: AppError(
          title: 'Konflik Data',
          message: serverMessage,
          code: API_CONFLICT_ERROR_CODE,
        ),
        exceptionType: type,
        errorCode: API_CONFLICT_ERROR_CODE,
        original: error,
        stackTrace: stackTrace,
        statusCode: statusCode,
      ),
      422 => ApiException(
        error: AppError(
          title: 'Validasi Gagal',
          message: serverMessage,
          code: API_UNPROCESSABLE_ERROR_CODE,
        ),
        exceptionType: type,
        errorCode: API_UNPROCESSABLE_ERROR_CODE,
        original: error,
        stackTrace: stackTrace,
        statusCode: statusCode,
      ),
      429 => ApiException(
        error: AppError(
          title: 'Terlalu Banyak Permintaan',
          message:
              'Anda telah mencapai batas permintaan. Tunggu sebentar lalu coba lagi.',
          code: API_TOO_MANY_REQUESTS_ERROR_CODE,
        ),
        exceptionType: type,
        errorCode: API_TOO_MANY_REQUESTS_ERROR_CODE,
        original: error,
        stackTrace: stackTrace,
        statusCode: statusCode,
      ),
      503 => ApiException(
        error: AppError(
          title: 'Layanan Tidak Tersedia',
          message:
              'Server sedang dalam pemeliharaan. Silakan coba lagi beberapa saat.',
          code: API_SERVICE_UNAVAILABLE_ERROR_CODE,
        ),
        exceptionType: type,
        errorCode: API_SERVICE_UNAVAILABLE_ERROR_CODE,
        original: error,
        stackTrace: stackTrace,
        statusCode: statusCode,
      ),
      int s when s >= 500 => ApiException(
        error: AppError(
          title: 'Kesalahan Server',
          message:
              'Terjadi kesalahan di server kami. Tim teknis sudah diberitahu.',
          code: API_SERVER_ERROR_CODE,
        ),
        exceptionType: type,
        errorCode: API_SERVER_ERROR_CODE,
        original: error,
        stackTrace: stackTrace,
        statusCode: statusCode,
      ),
      _ => ApiException(
        error: AppError(
          message: serverMessage,
          code: API_BAD_RESPONSE_ERROR_CODE,
        ),
        exceptionType: type,
        errorCode: API_BAD_RESPONSE_ERROR_CODE,
        original: error,
        stackTrace: stackTrace,
        statusCode: statusCode,
      ),
    };
  }

  String _extractMessageFromBody(dynamic body) {
    try {
      if (body is Map && body['message'] != null) {
        final message = body['message'].toString();
        return message.isNotEmpty ? message : "-";
      }
    } catch (_) {}
    return 'Terjadi kesalahan pada layanan. Silakan coba lagi dalam beberapa saat.';
  }
}
