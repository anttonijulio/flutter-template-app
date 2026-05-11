import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:template_app/core/errors/app_error.dart';
import 'package:template_app/core/constants/status_error_code.dart';
import 'package:template_app/core/services/caching/cache_manager.dart';
import 'package:template_app/core/services/location/location_service_helper.dart';
import 'package:template_app/core/services/location/model/location_data.dart';
import 'package:template_app/core/utilities/logger.dart';
import 'package:template_app/core/utilities/result.dart';

class LocationService {
  LocationService(this._cache, this._gmsLocationSettings);

  final CacheManager _cache;
  final GmsLocationSettingsDialog _gmsLocationSettings;

  static const String _logLabel = 'LocationService';
  static const String _cacheKey = 'location:current_location_data';

  Future<AppResult<LocationData>> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    bool enableCache = true,
    Duration cacheAge = const Duration(days: 1),
  }) async {
    try {
      Log.d('Getting current position', label: _logLabel);

      final guardResult = await _guard();
      if (guardResult != null) return Result.failure(guardResult);

      final data = await _cache.get<LocationData>(
        key: _cacheKey,
        fetcher: () => _fetchLocationData(accuracy),
        maxAge: cacheAge,
        forceRefresh: !enableCache,
        fromJson: (json) => LocationData.fromJson(json as Map<String, dynamic>),
        toJson: (d) => d.toJson(),
      );

      Log.i(
        'Position acquired: ${data.position.latitude}, ${data.position.longitude}'
        '${data.placemark != null ? " — ${data.placemark!.locality}" : ""}',
        label: _logLabel,
      );
      return Result.success(data);
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

  /// Menghitung jarak antara dua koordinat dalam meter.
  double distanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
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
    return _gmsLocationSettings.show();
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

  Future<LocationData> _fetchLocationData(LocationAccuracy accuracy) async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: accuracy),
    );

    Placemark? placemark;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      placemark = placemarks.isNotEmpty ? placemarks.first : null;
      Log.d('Placemark resolved: ${placemark?.locality}', label: _logLabel);
    } catch (e) {
      // Geocoding gagal tidak membatalkan operasi — placemark tetap null.
      Log.w('Geocoding failed, returning position only: $e', label: _logLabel);
    }

    return LocationData(position: position, placemark: placemark);
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
