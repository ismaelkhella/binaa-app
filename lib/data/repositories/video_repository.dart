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

  Future<void> downloadVideo(
    String videoId,
    String url, {
    String? token,
    required void Function(int received, int total) onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/v_$videoId.mp4';
    
    String finalUrl = url;
    if (!finalUrl.startsWith('http')) {
      final baseUrl = _dio.options.baseUrl.replaceFirst('/api', '');
      finalUrl = '$baseUrl${finalUrl.startsWith('/') ? '' : '/'}$finalUrl';
    }

    // Try to get MP4 rendition for Mux
    // If mp4_support: "standard" is enabled, Mux provides:
    // https://stream.mux.com/{PLAYBACK_ID}/{RESOLUTION}.mp4
    if (finalUrl.contains('stream.mux.com')) {
      if (finalUrl.endsWith('.m3u8')) {
        // Replace manifest with high quality mp4
        finalUrl = finalUrl.replaceAll('.m3u8', '/high.mp4');
      } else if (!finalUrl.endsWith('.mp4')) {
        // If it's just a playback ID URL, append /high.mp4
        finalUrl = '${finalUrl.endsWith('/') ? finalUrl : '$finalUrl/'}high.mp4';
      }
    }

    // Only add OUR download token if it's OUR server
    final isOurServer = finalUrl.contains(_dio.options.baseUrl.replaceFirst('/api', ''));
    if (isOurServer && token != null && token.isNotEmpty) {
      final connector = finalUrl.contains('?') ? '&' : '?';
      finalUrl = '$finalUrl${connector}token=$token';
    }

    final response = await _dio.download(
      finalUrl,
      path,
      onReceiveProgress: (received, total) {
        onProgress(received, total);
      },
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        // Clear default headers to avoid Mux rejecting the request
        headers: {},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode != 200) {
      // Clean up failed file
      final file = File(path);
      if (await file.exists()) await file.delete();
      throw Exception('فشل تحميل الفيديو: ${response.statusCode}');
    }
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
}
