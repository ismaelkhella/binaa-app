import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/cache_storage.dart';
import '../models/subject.dart';

class SubjectRepository {
  final Dio _dio;
  final CacheStorage _cache;
  SubjectRepository(this._dio, this._cache);

  Future<List<Subject>> listSubjects() async {
    try {
      final res = await _dio.get(ApiEndpoints.subjects);
      final list = (res.data as List?) ?? const [];
      final data = list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      await _cache.saveSubjects(data);
      return data.map((e) => Subject.fromJson(e)).toList();
    } catch (e) {
      final cached = await _cache.getSubjects();
      if (cached != null) {
        debugPrint('SubjectRepository: Loading subjects from cache');
        return cached
            .whereType<Map>()
            .map((e) => Subject.fromJson(e.cast<String, dynamic>()))
            .toList();
      }
      rethrow;
    }
  }

  Future<List<Subject>> listMySubjects() async {
    try {
      final res = await _dio.get(ApiEndpoints.mySubjects);
      final list = (res.data as List?) ?? const [];
      final data = list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      await _cache.saveMySubjects(data);
      return data.map((e) => Subject.fromJson(e)).toList();
    } catch (e) {
      final cached = await _cache.getMySubjects();
      if (cached != null) {
        debugPrint('SubjectRepository: Loading "my subjects" from cache');
        return cached
            .whereType<Map>()
            .map((e) => Subject.fromJson(e.cast<String, dynamic>()))
            .toList();
      }
      rethrow;
    }
  }

  Future<SubjectVideosResponse> getSubjectVideos(String subjectId) async {
    try {
      final res = await _dio.get(ApiEndpoints.subjectVideos(subjectId));
      final data = (res.data as Map).cast<String, dynamic>();
      await _cache.saveSubjectVideos(subjectId, data);
      return SubjectVideosResponse.fromJson(data);
    } catch (e) {
      final cached = await _cache.getSubjectVideos(subjectId);
      if (cached != null) {
        debugPrint('SubjectRepository: Loading videos for $subjectId from cache');
        return SubjectVideosResponse.fromJson(cached);
      }
      rethrow;
    }
  }
}
