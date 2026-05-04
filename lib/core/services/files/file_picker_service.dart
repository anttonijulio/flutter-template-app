import 'package:file_picker/file_picker.dart';

import '../../errors/app_error.dart';
import '../../utilities/logger.dart';
import '../../utilities/result.dart';

class FilePickerService {
  static const String _logLabel = 'FilePickerService';

  Future<AppResult<PlatformFile?>> pickSingle({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool withData = false,
    bool withReadStream = false,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        type: type,
        allowedExtensions: type == FileType.custom ? allowedExtensions : null,
        withData: withData,
        withReadStream: withReadStream,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        Log.i('Single file picker cancelled', label: _logLabel);
        return Result.success(null);
      }
      final file = result.files.first;
      Log.d('Picked file: ${file.name} (${file.size} bytes)', label: _logLabel);
      return Result.success(file);
    } catch (e, st) {
      Log.e('pickSingle failed', label: _logLabel, error: e, stackTrace: st);
      return Result.failure(AppError.fromException(e));
    }
  }

  Future<AppResult<List<PlatformFile>>> pickMultiple({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool withData = false,
    bool withReadStream = false,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        type: type,
        allowedExtensions: type == FileType.custom ? allowedExtensions : null,
        withData: withData,
        withReadStream: withReadStream,
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) {
        Log.i('Multi file picker cancelled', label: _logLabel);
        return Result.success([]);
      }
      Log.d('Picked ${result.files.length} file(s)', label: _logLabel);
      return Result.success(result.files);
    } catch (e, st) {
      Log.e('pickMultiple failed', label: _logLabel, error: e, stackTrace: st);
      return Result.failure(AppError.fromException(e));
    }
  }

  Future<AppResult<PlatformFile?>> pickImage({bool withData = false}) =>
      pickSingle(type: FileType.image, withData: withData);

  Future<AppResult<PlatformFile?>> pickVideo({bool withData = false}) =>
      pickSingle(type: FileType.video, withData: withData);

  Future<AppResult<PlatformFile?>> pickAudio({bool withData = false}) =>
      pickSingle(type: FileType.audio, withData: withData);

  Future<AppResult<PlatformFile?>> pickDocument({
    List<String> extensions = const [
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
    ],
    bool withData = false,
  }) => pickSingle(
    type: FileType.custom,
    allowedExtensions: extensions,
    withData: withData,
  );

  Future<void> clearTemporaryFiles() async {
    try {
      await FilePicker.clearTemporaryFiles();
      Log.d('Temporary files cleared', label: _logLabel);
    } catch (e, st) {
      Log.w(
        'clearTemporaryFiles failed',
        label: _logLabel,
        error: e,
        stackTrace: st,
      );
    }
  }
}
