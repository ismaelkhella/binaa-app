import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/cache_storage.dart';
import '../../core/storage/offline_storage.dart';
import '../models/video.dart';

class VideoRepository {
  final Dio _dio;
  final CacheStorage _cache;
  final OfflineStorage _offline;
  VideoRepository(this._dio, this._cache, this._offline);

  Future<StreamTokenResponse> stream(String videoId) async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.videoStream(videoId));
      return StreamTokenResponse.fromJson(
        (res.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<LessonDetailsResponse> getVideoDetails(String videoId) async {
    try {
      final res = await _dio.get(ApiEndpoints.video(videoId));
      final data = (res.data as Map).cast<String, dynamic>();
      await _cache.saveLessonDetails(videoId, data);
      return LessonDetailsResponse.fromJson(data);
    } catch (e) {
      final cached = await _cache.getLessonDetails(videoId);
      if (cached != null) {
        debugPrint('VideoRepository: Loading lesson details from cache');
        return LessonDetailsResponse.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<VideoViewTracker> markViewed(String videoId) async {
    return runApiCall(() async {
      final res = await _dio.post(ApiEndpoints.videoMarkViewed(videoId));
      return VideoViewTracker.fromJson(
        (res.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<DownloadToken> downloadToken(String videoId) async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.videoDownloadToken(videoId));
      return DownloadToken.fromJson(
        (res.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<String?> getLocalPath(String videoId) async {
    final download = await _offline.getDownload(videoId);
    if (download != null && download.status == 2 && download.localPath.isNotEmpty) {
      final file = File(download.localPath);
      if (await file.exists()) {
        return download.localPath;
      }
    }
    return null;
  }

  Future<void> deleteDownloadedVideo(String videoId) async {
    final download = await _offline.getDownload(videoId);
    if (download != null && download.localPath.isNotEmpty) {
      final file = File(download.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  String resolveMuxDownloadUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.contains('stream.mux.com')) return url;

    final segments = List<String>.from(uri.pathSegments);
    if (segments.isEmpty) return url;

    final last = segments.removeLast();
    String newLast;
    if (last.endsWith('.mp4')) {
      return url; // Already mp4
    } else if (last.endsWith('.m3u8')) {
      final playbackId = last.substring(0, last.length - '.m3u8'.length);
      newLast = '$playbackId/highest.mp4';
    } else {
      newLast = '$last/highest.mp4';
    }

    return uri.replace(path: '/${[...segments, newLast].join('/')}').toString();
  }
}
