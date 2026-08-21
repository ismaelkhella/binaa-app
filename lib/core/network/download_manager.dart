import 'dart:async';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/downloaded_video.dart';
import '../storage/offline_storage.dart';

class DownloadManager {
  final OfflineStorage _storage;
  
  final _progressController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get progressStream => _progressController.stream;
  
  final Map<String, double> _currentProgress = {};
  double? getProgress(String taskId) => _currentProgress[taskId];

  DownloadManager(this._storage) {
    _init();
  }

  void _init() {
    FileDownloader().updates.listen((update) {
      if (update is TaskProgressUpdate) {
        _currentProgress[update.task.taskId] = update.progress;
        _progressController.add({update.task.taskId: update.progress});
      } else if (update is TaskStatusUpdate) {
        _handleStatusUpdate(update);
      }
    });

    FileDownloader().configure(
      globalConfig: [
        (Config.requestTimeout, const Duration(seconds: 100)),
      ],
    ).then((_) {
      FileDownloader().trackTasks();
    });
  }

  Future<void> _handleStatusUpdate(TaskStatusUpdate update) async {
    final taskId = update.task.taskId;
    final status = update.status;
    
    debugPrint('Download status for $taskId: $status');

    if (status == TaskStatus.complete) {
      _currentProgress.remove(taskId);
      await _finalizeDownload(taskId);
    } else if (status == TaskStatus.failed || status == TaskStatus.notFound) {
      _currentProgress.remove(taskId);
      await _handleFailure(taskId);
    } else if (status == TaskStatus.canceled) {
      _currentProgress.remove(taskId);
      await _storage.deleteDownload(taskId);
    }
  }

  Future<void> startDownload({
    required String videoId,
    required String url,
    required String title,
    required String subHeader,
    String? unitName,
    String? thumbnail,
    int durationSec = 0,
    Map<String, String>? headers,
  }) async {
    final existing = await _storage.getDownload(videoId);
    if (existing != null && (existing.status == 1 || existing.status == 2)) {
      return;
    }

    // Ensure we have a valid URL for background_downloader (it doesn't support HLS/m3u8)
    if (url.contains('.m3u8')) {
      debugPrint('Warning: background_downloader may not support .m3u8 directly');
    }

    final task = DownloadTask(
      taskId: videoId,
      url: url,
      filename: 'video_$videoId.mp4',
      directory: 'videos',
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
      retries: 3,
      allowPause: true,
      headers: headers ?? {},
      displayName: title,
    );

    final downloadVideo = DownloadedVideo()
      ..videoId = videoId
      ..title = title
      ..subHeader = subHeader
      ..unitName = unitName
      ..thumbnail = thumbnail
      ..localPath = ''
      ..downloadedAt = DateTime.now()
      ..sizeInBytes = 0
      ..durationSec = durationSec
      ..status = 1;

    await _storage.saveDownload(downloadVideo);
    
    final success = await FileDownloader().enqueue(task);
    if (!success) {
      downloadVideo.status = 3;
      await _storage.saveDownload(downloadVideo);
      throw Exception('تعذر بدء التحميل');
    }
  }

  Future<void> _finalizeDownload(String taskId) async {
    final video = await _storage.getDownload(taskId);
    if (video == null) return;

    final task = await FileDownloader().taskForId(taskId);
    if (task == null) return;

    final path = await task.filePath();
    
    video.localPath = path;
    video.status = 2;
    video.downloadedAt = DateTime.now();
    
    try {
      final file = File(path);
      if (await file.exists()) {
        video.sizeInBytes = await file.length();
      }
    } catch (_) {}

    await _storage.saveDownload(video);
  }

  Future<void> _handleFailure(String taskId) async {
    final video = await _storage.getDownload(taskId);
    if (video != null) {
      video.status = 3;
      await _storage.saveDownload(video);
    }
  }

  Future<void> cancelDownload(String videoId) async {
    final task = await FileDownloader().taskForId(videoId);
    if (task != null) {
      await FileDownloader().cancelTasksWithIds([videoId]);
    }
    await _storage.deleteDownload(videoId);
  }

  Future<void> pauseDownload(String videoId) async {
    final task = await FileDownloader().taskForId(videoId);
    if (task is DownloadTask) {
      await FileDownloader().pause(task);
    }
  }

  Future<void> resumeDownload(String videoId) async {
    final task = await FileDownloader().taskForId(videoId);
    if (task is DownloadTask) {
      await FileDownloader().resume(task);
    }
  }

  void dispose() {
    _progressController.close();
  }
}
