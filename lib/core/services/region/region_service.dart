import 'package:template_app/core/errors/app_error.dart';
import 'package:template_app/core/services/caching/cache_manager.dart';
import 'package:template_app/core/services/datasources/api/dio_client.dart';
import 'package:template_app/core/services/region/models/region_response.dart';
import 'package:template_app/core/utilities/logger.dart';
import 'package:template_app/core/utilities/result.dart';

class RegionService {
  static const String _logLabel = 'RegionService';
  static const Duration _defaultCacheAge = Duration(days: 7);

  final DioClient _client;
  final CacheManager _cache;

  RegionService(this._client, this._cache);

  Future<AppResult<RegionResponse>> getProvinces({
    bool refresh = false,
    Duration cacheAge = _defaultCacheAge,
  }) {
    return _cached(
      'region:provinces',
      () => _fetch('/provinces.json'),
      refresh: refresh,
      cacheAge: cacheAge,
    );
  }

  Future<AppResult<RegionResponse>> getRegencies(
    String provinceCode, {
    bool refresh = false,
    Duration cacheAge = _defaultCacheAge,
  }) {
    return _cached(
      'region:regencies:$provinceCode',
      () => _fetch('/regencies/$provinceCode.json'),
      refresh: refresh,
      cacheAge: cacheAge,
    );
  }

  Future<AppResult<RegionResponse>> getDistricts(
    String regencyCode, {
    bool refresh = false,
    Duration cacheAge = _defaultCacheAge,
  }) {
    return _cached(
      'region:districts:$regencyCode',
      () => _fetch('/districts/$regencyCode.json'),
      refresh: refresh,
      cacheAge: cacheAge,
    );
  }

  Future<AppResult<RegionResponse>> getVillages(
    String districtCode, {
    bool refresh = false,
    Duration cacheAge = _defaultCacheAge,
  }) {
    return _cached(
      'region:villages:$districtCode',
      () => _fetch('/villages/$districtCode.json'),
      refresh: refresh,
      cacheAge: cacheAge,
    );
  }

  Future<AppResult<RegionResponse>> _cached(
    String key,
    Future<RegionResponse> Function() fetcher, {
    required bool refresh,
    required Duration cacheAge,
  }) async {
    try {
      final data = await _cache.get<RegionResponse>(
        key: key,
        fetcher: fetcher,
        maxAge: refresh ? null : cacheAge,
        forceRefresh: refresh,
        staleWhileRevalidate: !refresh,
        fromJson: (json) => RegionResponse.fromJson(json as Map<String, dynamic>),
        toJson: (data) => data.toJson(),
      );
      Log.d('loaded: $key', label: _logLabel);
      return Result.success(data);
    } catch (e, st) {
      Log.e('failed: $key', label: _logLabel, error: e, stackTrace: st);
      return Result.failure(AppError.fromException(e));
    }
  }

  Future<RegionResponse> _fetch(String endpoint) async {
    final response = await _client.get(endpoint: endpoint);
    return RegionResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
