// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:equatable/equatable.dart';

import '../../errors/app_error.dart';
import '../../utilities/logger.dart';
import '../../utilities/result.dart';

/// File category — drives where the file is moved after download.
enum DownloadFileType { image, video, document }

/// Plugin-agnostic download status. Mirrors the underlying plugin's status
/// enum so callers don't need to import `background_downloader`.
enum DownloadStatus {
  enqueued,
  running,
  complete,
  notFound,
  failed,
  canceled,
  paused,
  waitingToRetry,
}

/// Single download request used by the batch API.
class DownloadFileRequest extends Equatable {
  final String url;
  final String filename;
  final DownloadFileType type;

  const DownloadFileRequest({
    required this.url,
    required this.filename,
    required this.type,
  });

  @override
  List<Object> get props => [url, filename, type];

  DownloadFileRequest copyWith({
    String? url,
    String? filename,
    DownloadFileType? type,
  }) {
    return DownloadFileRequest(
      url: url ?? this.url,
      filename: filename ?? this.filename,
      type: type ?? this.type,
    );
  }
}

/// Per-file outcome of a download (single or one entry of a batch).
class DownloadResult extends Equatable {
  final String filename;
  final DownloadStatus status;
  final String? filePath;

  const DownloadResult({
    required this.filename,
    required this.status,
    this.filePath,
  });

  bool get isSuccess => status == DownloadStatus.complete;

  @override
  List<Object?> get props => [filename, status, filePath];

  DownloadResult copyWith({
    String? filename,
    DownloadStatus? status,
    String? filePath,
  }) {
    return DownloadResult(
      filename: filename ?? this.filename,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'filename': filename,
      'status': status.name,
      'filePath': filePath,
    };
  }
}

/// Aggregated outcome of a batch download.
class DownloadBatchResult extends Equatable {
  final List<DownloadResult> succeeded;
  final List<DownloadResult> failed;

  const DownloadBatchResult({required this.succeeded, required this.failed});

  int get numSucceeded => succeeded.length;
  int get numFailed => failed.length;
  int get total => numSucceeded + numFailed;
  bool get hasFailures => failed.isNotEmpty;

  @override
  List<Object> get props => [succeeded, failed];

  DownloadBatchResult copyWith({
    List<DownloadResult>? succeeded,
    List<DownloadResult>? failed,
  }) {
    return DownloadBatchResult(
      succeeded: succeeded ?? this.succeeded,
      failed: failed ?? this.failed,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'succeeded': succeeded.map((x) => x.toJson()).toList(),
      'failed': failed.map((x) => x.toJson()).toList(),
    };
  }
}

class DownloadService {
  static const String _logLabel = 'DownloadService';

  StreamSubscription<TaskUpdate>? _updatesSubscription;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      Log.w('init() called again — ignoring', label: _logLabel);
      return;
    }
    _updatesSubscription = FileDownloader().updates.listen(_handleGlobalUpdate);
    _initialized = true;
    Log.i('Initialized', label: _logLabel);
  }

  Future<void> dispose() async {
    await _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _initialized = false;
    Log.i('Disposed', label: _logLabel);
  }

  Future<AppResult<DownloadResult>> downloadFile({
    required DownloadFileType type,
    required String url,
    required String filename,
    void Function(double progress)? onProgress,
    void Function(DownloadStatus status)? onStatus,
    bool showNotification = true,
  }) async {
    if (url.isEmpty || filename.isEmpty) {
      return Result.failure(
        const AppError(
          title: 'Permintaan Tidak Valid',
          message: 'URL dan nama file tidak boleh kosong.',
        ),
      );
    }

    try {
      final task = DownloadTask(
        url: url,
        filename: filename,
        updates: Updates.statusAndProgress,
      );

      if (showNotification) _configureTaskNotification(task, filename);

      final update = await FileDownloader().download(
        task,
        onProgress: _safeProgress(onProgress),
        onStatus: _safeStatus(onStatus),
      );

      if (update.status == TaskStatus.complete) {
        final path = await _moveToStorage(update.task, type);
        Log.d('Downloaded: $filename → $path', label: _logLabel);
        return Result.success(
          DownloadResult(
            filename: filename,
            status: DownloadStatus.complete,
            filePath: path,
          ),
        );
      }

      Log.w(
        'Download ended: $filename → ${update.status.name}',
        label: _logLabel,
        error: update.exception,
      );
      return Result.failure(_errorFromUpdate(update, filename));
    } catch (e, st) {
      Log.e('downloadFile failed', label: _logLabel, error: e, stackTrace: st);
      return Result.failure(AppError.fromException(e));
    }
  }

  Future<AppResult<DownloadBatchResult>> downloadBatch({
    required List<DownloadFileRequest> requests,
    void Function(int succeeded, int failed)? onBatchProgress,
    bool showNotification = true,
  }) async {
    if (requests.isEmpty) {
      return Result.failure(
        const AppError(
          title: 'Permintaan Tidak Valid',
          message: 'Daftar unduhan kosong.',
        ),
      );
    }

    try {
      final taskMap = <String, DownloadFileRequest>{};
      final tasks = requests.map((r) {
        final task = DownloadTask(
          url: r.url,
          filename: r.filename,
          updates: Updates.statusAndProgress,
        );
        taskMap[task.taskId] = r;
        if (showNotification) _configureTaskNotification(task, r.filename);
        return task;
      }).toList();

      final batch = await FileDownloader().downloadBatch(
        tasks,
        batchProgressCallback: _safeBatchProgress(onBatchProgress),
      );

      final succeeded = <DownloadResult>[];
      for (final task in batch.succeeded) {
        final req = taskMap[task.taskId];
        final path = await _moveToStorage(
          task,
          req?.type ?? DownloadFileType.document,
        );
        succeeded.add(
          DownloadResult(
            filename: req?.filename ?? _filenameOf(task),
            status: DownloadStatus.complete,
            filePath: path,
          ),
        );
      }

      final failed = <DownloadResult>[];
      for (final task in batch.failed) {
        final req = taskMap[task.taskId];
        final pluginStatus = batch.results[task] ?? TaskStatus.failed;
        failed.add(
          DownloadResult(
            filename: req?.filename ?? _filenameOf(task),
            status: _mapStatus(pluginStatus),
          ),
        );
      }

      Log.d(
        'Batch complete: ${succeeded.length} ok, ${failed.length} failed',
        label: _logLabel,
      );
      return Result.success(
        DownloadBatchResult(succeeded: succeeded, failed: failed),
      );
    } catch (e, st) {
      Log.e('downloadBatch failed', label: _logLabel, error: e, stackTrace: st);
      return Result.failure(AppError.fromException(e));
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

  Future<String?> _moveToStorage(Task task, DownloadFileType type) async {
    if (task is! DownloadTask) return null;
    switch (type) {
      case DownloadFileType.image:
        return FileDownloader().moveToSharedStorage(task, SharedStorage.images);
      case DownloadFileType.video:
        return FileDownloader().moveToSharedStorage(task, SharedStorage.video);
      case DownloadFileType.document:
        if (Platform.isAndroid) {
          return FileDownloader().moveToSharedStorage(
            task,
            SharedStorage.downloads,
          );
        }
        // iOS: file stays in BaseDirectory.applicationDocuments
        return task.filePath();
    }
  }

  void _configureTaskNotification(DownloadTask task, String filename) {
    if (Platform.isAndroid) {
      FileDownloader().configureNotificationForTask(
        task,
        running: TaskNotification('Mengunduh...', '$filename\n{progress}'),
        complete: TaskNotification('Unduhan Selesai', filename),
        error: TaskNotification('Unduhan Gagal', filename),
        progressBar: true,
      );
    } else {
      FileDownloader().configureNotificationForTask(
        task,
        complete: TaskNotification('Unduhan Selesai', filename),
        error: TaskNotification('Unduhan Gagal', filename),
        progressBar: false,
      );
    }
  }

  AppError _errorFromUpdate(TaskStatusUpdate update, String filename) {
    final reason = switch (update.status) {
      TaskStatus.notFound => 'Berkas tidak ditemukan di server.',
      TaskStatus.canceled => 'Unduhan dibatalkan.',
      TaskStatus.paused => 'Unduhan terjeda.',
      TaskStatus.failed =>
        update.exception?.description ??
            'Unduhan gagal karena alasan yang tidak diketahui.',
      _ => 'Status: ${update.status.name}',
    };
    return AppError(
      title: 'Unduhan Gagal',
      message: 'Gagal mengunduh $filename. $reason',
    );
  }

  DownloadStatus _mapStatus(TaskStatus status) => switch (status) {
    TaskStatus.enqueued => DownloadStatus.enqueued,
    TaskStatus.running => DownloadStatus.running,
    TaskStatus.complete => DownloadStatus.complete,
    TaskStatus.notFound => DownloadStatus.notFound,
    TaskStatus.failed => DownloadStatus.failed,
    TaskStatus.canceled => DownloadStatus.canceled,
    TaskStatus.paused => DownloadStatus.paused,
    TaskStatus.waitingToRetry => DownloadStatus.waitingToRetry,
  };

  String _filenameOf(Task task) =>
      task is DownloadTask ? task.filename : task.taskId;

  void Function(double)? _safeProgress(void Function(double)? cb) {
    if (cb == null) return null;
    return (progress) {
      try {
        cb(progress);
      } catch (e, st) {
        Log.w(
          'onProgress callback threw',
          label: _logLabel,
          error: e,
          stackTrace: st,
        );
      }
    };
  }

  void Function(TaskStatus)? _safeStatus(void Function(DownloadStatus)? cb) {
    if (cb == null) return null;
    return (status) {
      try {
        cb(_mapStatus(status));
      } catch (e, st) {
        Log.w(
          'onStatus callback threw',
          label: _logLabel,
          error: e,
          stackTrace: st,
        );
      }
    };
  }

  void Function(int, int)? _safeBatchProgress(void Function(int, int)? cb) {
    if (cb == null) return null;
    return (succeeded, failed) {
      try {
        cb(succeeded, failed);
      } catch (e, st) {
        Log.w(
          'onBatchProgress callback threw',
          label: _logLabel,
          error: e,
          stackTrace: st,
        );
      }
    };
  }

  void _handleGlobalUpdate(TaskUpdate update) {
    if (update is TaskStatusUpdate) {
      Log.t(
        'Global status: ${update.task.taskId} → ${update.status.name}',
        label: _logLabel,
      );
    }
  }
}
