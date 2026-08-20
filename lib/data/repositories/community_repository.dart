import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/community.dart';

class CommunityRepository {
  final Dio _dio;
  CommunityRepository(this._dio);

  Future<List<CommunitySubject>> getSubjects() async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.communitySubjects);
      return (res.data as List)
          .map((e) => CommunitySubject.fromJson(e.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<List<CommunityMessage>> getMessages(String subjectId, {String? before}) async {
    return runApiCall(() async {
      final res = await _dio.get(
        ApiEndpoints.communityMessages(subjectId),
        queryParameters: {if (before != null) 'before': before},
      );
      return (res.data as List)
          .map((e) => CommunityMessage.fromJson(e.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<CommunityMessage> sendMessage(
    String subjectId, {
    String? content,
    CommunityMessageType? type,
    File? file,
  }) async {
    return runApiCall(() async {
      final formData = FormData.fromMap({
        if (content != null) 'content': content,
        if (type != null) 'type': type.name,
        if (file != null)
          'file': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
      });

      final res = await _dio.post(
        ApiEndpoints.communityMessages(subjectId),
        data: formData,
      );
      return CommunityMessage.fromJson((res.data as Map).cast<String, dynamic>());
    });
  }
}
