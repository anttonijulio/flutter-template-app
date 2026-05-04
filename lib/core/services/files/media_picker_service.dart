import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../errors/app_error.dart';
import '../../constants/status_error_code.dart';
import '../../utilities/logger.dart';
import '../../utilities/result.dart';

class MediaPickerService {
  MediaPickerService(this._picker);

  final ImagePicker _picker;

  static const String _logLabel = 'MediaPickerService';

  Future<AppResult<bool>> _requestPermission(Permission permission) async {
    final status = await permission.request();
    Log.d('Permission ${permission.value}: $status', label: _logLabel);
    if (status.isGranted || status.isLimited) return Result.success(true);
    if (status.isPermanentlyDenied) {
      return Result.failure(
        AppError(
          title: 'Izin Ditolak',
          message:
              'Izin diperlukan untuk mengakses fitur ini. Aktifkan melalui Pengaturan aplikasi.',
          code: PERMISSION_PERMANENTLY_DENIED_ERROR_CODE,
        ),
      );
    }
    return Result.failure(
      const AppError(
        title: 'Izin Ditolak',
        message: 'Izin diperlukan untuk mengakses fitur ini.',
        code: PERMISSION_DENIED_ERROR_CODE,
      ),
    );
  }

  Future<AppResult<XFile?>> pickFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final permission = await _requestPermission(Permission.photos);
    if (permission.isFailure) return Result.failure(permission.errorOrNull!);

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      Log.d(
        file != null
            ? 'Picked from gallery: ${file.path}'
            : 'Gallery picker cancelled',
        label: _logLabel,
      );
      return Result.success(file);
    } catch (e, st) {
      Log.e(
        'pickFromGallery failed',
        label: _logLabel,
        error: e,
        stackTrace: st,
      );
      return Result.failure(AppError.fromException(e));
    }
  }

  Future<AppResult<XFile?>> pickFromCamera({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCamera = CameraDevice.rear,
  }) async {
    final permission = await _requestPermission(Permission.camera);
    if (permission.isFailure) return Result.failure(permission.errorOrNull!);

    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCamera,
      );
      Log.d(
        file != null
            ? 'Picked from camera: ${file.path}'
            : 'Camera picker cancelled',
        label: _logLabel,
      );
      return Result.success(file);
    } catch (e, st) {
      Log.e(
        'pickFromCamera failed',
        label: _logLabel,
        error: e,
        stackTrace: st,
      );
      return Result.failure(AppError.fromException(e));
    }
  }

  Future<AppResult<List<XFile>>> pickMultipleFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    final permission = await _requestPermission(Permission.photos);
    if (permission.isFailure) return Result.failure(permission.errorOrNull!);

    try {
      final files = await _picker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        limit: limit,
      );
      Log.d(
        files.isNotEmpty
            ? 'Picked ${files.length} image(s) from gallery'
            : 'Multi-image picker cancelled',
        label: _logLabel,
      );
      return Result.success(files);
    } catch (e, st) {
      Log.e(
        'pickMultipleFromGallery failed',
        label: _logLabel,
        error: e,
        stackTrace: st,
      );
      return Result.failure(AppError.fromException(e));
    }
  }

  Future<AppResult<XFile?>> pickVideo({
    required ImageSource source,
    Duration? maxDuration,
    CameraDevice preferredCamera = CameraDevice.rear,
  }) async {
    final permission = source == ImageSource.camera
        ? await _requestPermission(Permission.camera)
        : await _requestPermission(Permission.photos);
    if (permission.isFailure) return Result.failure(permission.errorOrNull!);

    try {
      final file = await _picker.pickVideo(
        source: source,
        maxDuration: maxDuration,
        preferredCameraDevice: preferredCamera,
      );
      Log.d(
        file != null ? 'Picked video: ${file.path}' : 'Video picker cancelled',
        label: _logLabel,
      );
      return Result.success(file);
    } catch (e, st) {
      Log.e('pickVideo failed', label: _logLabel, error: e, stackTrace: st);
      return Result.failure(AppError.fromException(e));
    }
  }
}
