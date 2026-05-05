import 'package:geolocator/geolocator.dart';
import 'package:template_app/core/errors/app_error.dart';
import 'package:template_app/core/constants/status_error_code.dart';
import 'package:template_app/core/services/caching/cache_manager.dart';
import 'package:template_app/core/utilities/logger.dart';
import 'package:template_app/core/utilities/result.dart';

class LocationService {
  LocationService(this._cache);

  final CacheManager _cache;

  static const String _logLabel = 'LocationService';
  static const String _cacheKey = 'location:current_position';

  Future<AppResult<Position>> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    bool enableCache = true,
    Duration cacheAge = const Duration(days: 1),
  }) async {
    try {
      Log.d('Getting current position', label: _logLabel);

      final guardResult = await _guard();
      if (guardResult != null) return Result.failure(guardResult);

      final position = await _cache.get<Position>(
        key: _cacheKey,
        fetcher: () => Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: accuracy),
        ),
        maxAge: cacheAge,
        forceRefresh: !enableCache,
        fromJson: (json) => Position.fromMap(json as Map<String, dynamic>),
        toJson: (p) => p.toJson(),
      );

      Log.i(
        'Position acquired: ${position.latitude}, ${position.longitude}',
        label: _logLabel,
      );
      return Result.success(position);
    } catch (e, s) {
      Log.e(
        'Failed to get position',
        label: _logLabel,
        error: e,
        stackTrace: s,
      );
      return Result.failure(AppError.fromException(e));
    }
  }

  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 0,
  }) {
    Log.d('Starting position stream', label: _logLabel);
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  Future<bool> get isServiceEnabled => Geolocator.isLocationServiceEnabled();

  Future<bool> get isPermissionGranted async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<AppResult<bool>> requestPermission() async {
    Log.d('Requesting location permission', label: _logLabel);
    final error = await _guard();
    if (error != null) return Result.failure(error);
    Log.i('Location permission granted', label: _logLabel);
    return Result.success(true);
  }

  Future<AppError?> _guard() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Log.w('Location service is disabled', label: _logLabel);
      return const AppError(
        title: 'GPS Tidak Aktif',
        message:
            'Layanan lokasi tidak aktif. Aktifkan GPS pada pengaturan perangkat.',
        code: LOCATION_SERVICE_DISABLED_ERROR_CODE,
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    Log.d('Permission status: $permission', label: _logLabel);

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      Log.d('Permission after request: $permission', label: _logLabel);
    }

    if (permission == LocationPermission.deniedForever) {
      Log.w('Location permission permanently denied', label: _logLabel);
      return const AppError(
        title: 'Izin Lokasi Ditolak',
        message:
            'Izin lokasi ditolak secara permanen. Buka pengaturan aplikasi untuk mengizinkan akses lokasi.',
        code: LOCATION_PERMISSION_DENIED_FOREVER_ERROR_CODE,
      );
    }

    if (permission == LocationPermission.denied) {
      Log.w('Location permission denied', label: _logLabel);
      return const AppError(
        title: 'Izin Lokasi Diperlukan',
        message: 'Izin akses lokasi diperlukan untuk menggunakan fitur ini.',
        code: LOCATION_PERMISSION_DENIED_ERROR_CODE,
      );
    }

    return null;
  }
}
