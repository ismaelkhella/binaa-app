import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/qb.dart';

class QbRepository {
  final Dio _dio;

  QbRepository(this._dio);

  Future<List<QbSubject>> getSubjects() async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.qbSubjects);
      final list = (res.data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => QbSubject.fromJson(e.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<List<QbUnit>> getUnits(String subjectId) async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.qbUnits(subjectId));
      final list = (res.data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => QbUnit.fromJson(e.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<List<QbQuestion>> getQuestions(String unitId) async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.qbQuestions(unitId));
      final list = (res.data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => QbQuestion.fromJson(e.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<QbAnswerResponse> answerQuestion(String questionId, String choiceId) async {
    return runApiCall(() async {
      final res = await _dio.post(
        ApiEndpoints.qbAnswer(questionId),
        data: {'choiceId': choiceId},
      );
      return QbAnswerResponse.fromJson(
        (res.data as Map).cast<String, dynamic>(),
      );
    });
  }
}
