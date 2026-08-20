import 'dart:async';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../data/models/downloaded_video.dart';
import '../storage/offline_storage.dart';

class DownloadManager {
  final OfflineStorage _storage;
  
  final _progressController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get progressStream => _progressController.stream;

  DownloadManager(this._storage) {
    _init();
  }

  void _init() {
    FileDownloader().configure(
      globalConfig: [
        (Config.requestTimeout, const Duration(seconds: 100)),
      ],
    ).then((_) {
      // Version 8.x uses a single stream for all updates
      FileDownloader().updates.listen((update) async {
        if (update is TaskProgressUpdate) {
          _progressController.add({update.task.taskId: update.progress});
        } else if (update is TaskStatusUpdate) {
          debugPrint('Download status for ${update.task.taskId}: ${update.status}');
          if (update.status == TaskStatus.complete) {
            await _finalizeDownload(update.task.taskId);
          } else if (update.status == TaskStatus.failed) {
            await _handleFailure(update.task.taskId);
          }
        }
      });
    });
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
    // Prevent duplicate downloads
    final existing = await _storage.getDownload(videoId);
    if (existing != null && (existing.status == 1 || existing.status == 2)) {
      return;
    }

    final task = DownloadTask(
      taskId: videoId,
      url: url,
      filename: 'v_$videoId.mp4',
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
      ..status = 1; // Downloading

    await _storage.saveDownload(downloadVideo);
    
    final success = await FileDownloader().enqueue(task);
    if (!success) {
      downloadVideo.status = 3; // Failed
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
    video.status = 2; // Completed
    video.downloadedAt = DateTime.now();
    
    // Attempt to get file size
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
      video.status = 3; // Failed
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
