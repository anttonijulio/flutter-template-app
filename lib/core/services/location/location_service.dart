import 'package:geolocator/geolocator.dart';
import 'package:template_app/core/errors/app_error.dart';
import 'package:template_app/core/constants/status_error_code.dart';
import 'package:template_app/core/services/caching/cache_manager.dart';
import 'package:template_app/core/services/location/location_service_helper.dart';
import 'package:template_app/core/utilities/logger.dart';
import 'package:template_app/core/utilities/result.dart';

class LocationService {
  LocationService(this._cache, this._serviceHelper);

  final CacheManager _cache;
  final LocationServiceHelper _serviceHelper;

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

  /// Menampilkan dialog native GPS enable (Android: Play Services dialog,
  /// iOS: cek status tanpa dialog). Return true jika GPS aktif setelah dialog.
  Future<bool> requestService() {
    Log.d('Requesting location service via native dialog', label: _logLabel);
    return _serviceHelper.requestService();
  }

  /// Meminta izin lokasi dari user. Return failure jika ditolak atau
  /// ditolak permanen.
  Future<AppResult<bool>> requestPermission() async {
    Log.d('Requesting location permission', label: _logLabel);
    final permission = await Geolocator.requestPermission();
    Log.d('Permission result: $permission', label: _logLabel);

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Log.i('Location permission granted', label: _logLabel);
      return Result.success(true);
    }

    if (permission == LocationPermission.deniedForever) {
      Log.w('Location permission permanently denied', label: _logLabel);
      return Result.failure(
        const AppError(
          title: 'Izin Lokasi Ditolak',
          message:
              'Izin lokasi ditolak secara permanen. Buka pengaturan aplikasi untuk mengizinkan akses lokasi.',
          code: LOCATION_PERMISSION_DENIED_FOREVER_ERROR_CODE,
        ),
      );
    }

    Log.w('Location permission denied', label: _logLabel);
    return Result.failure(
      const AppError(
        title: 'Izin Lokasi Diperlukan',
        message: 'Izin akses lokasi diperlukan untuk menggunakan fitur ini.',
        code: LOCATION_PERMISSION_DENIED_ERROR_CODE,
      ),
    );
  }

  /// Membuka halaman pengaturan aplikasi di sistem.
  /// Gunakan saat permission berstatus deniedForever.
  Future<bool> openAppSettings() {
    Log.d('Opening app settings', label: _logLabel);
    return Geolocator.openAppSettings();
  }

  /// Membuka halaman pengaturan lokasi di sistem.
  /// Gunakan sebagai fallback jika dialog native GPS tidak tersedia.
  Future<bool> openLocationSettings() {
    Log.d('Opening location settings', label: _logLabel);
    return Geolocator.openLocationSettings();
  }

  /// Hanya mengecek status GPS dan izin, tanpa side effect apapun.
  /// Return AppError jika salah satu kondisi belum terpenuhi.
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

    final permission = await Geolocator.checkPermission();
    Log.d('Permission status: $permission', label: _logLabel);

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
