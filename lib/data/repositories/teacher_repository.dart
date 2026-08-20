import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/teacher.dart';

class TeacherRepository {
  final Dio _dio;
  TeacherRepository(this._dio);

  Future<TeacherDashboard> getDashboard() async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.teacherDashboard);
      return TeacherDashboard.fromJson((res.data as Map).cast<String, dynamic>());
    });
  }
}
