import 'package:dio/dio.dart';
import 'package:template_app/core/services/datasources/api/dio_client.dart';
import 'package:template_app/core/services/datasources/api/response_dto.dart';

typedef ReceivedProgressCallback = void Function(int received, int total);
typedef SendProgressCallback = void Function(int count, int total);

class AppApiClient {
  final DioClient _client;

  AppApiClient(this._client);

  Future<ResponseDto<T>> get<T>({
    required String endpoint,
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    Map<String, dynamic>? queryParams,
    ReceivedProgressCallback? onReceiveProgress,
  }) async {
    final res = await _client.get(
      endpoint: endpoint,
      data: data,
      options: options,
      cancelToken: cancelToken,
      queryParams: queryParams,
      onReceiveProgress: onReceiveProgress,
    );
    return ResponseDto.fromJson(res.data);
  }

  Future<ResponseDto<T>> post<T>({
    required String endpoint,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    SendProgressCallback? onSendProgress,
    ReceivedProgressCallback? onReceiveProgress,
  }) async {
    final res = await _client.post(
      endpoint: endpoint,
      data: data,
      options: options,
      cancelToken: cancelToken,
      queryParameters: queryParameters,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return ResponseDto.fromJson(res.data);
  }

  Future<ResponseDto<T>> put<T>({
    required String endpoint,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    SendProgressCallback? onSendProgress,
    ReceivedProgressCallback? onReceiveProgress,
  }) async {
    final res = await _client.put(
      endpoint: endpoint,
      data: data,
      options: options,
      cancelToken: cancelToken,
      queryParameters: queryParameters,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return ResponseDto.fromJson(res.data);
  }

  Future<ResponseDto<T>> delete<T>({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Object? data,
    Options? options,
  }) async {
    final res = await _client.delete(
      endpoint: endpoint,
      data: data,
      options: options,
      cancelToken: cancelToken,
      queryParameters: queryParameters,
    );
    return ResponseDto.fromJson(res.data);
  }
}
