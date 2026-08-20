import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/admin_dashboard.dart';
import '../models/api_enums.dart';
import '../models/user.dart';

class AdminStudentFilter {
  final Grade? grade;
  final Branch? branch;
  final String? search;
  const AdminStudentFilter({this.grade, this.branch, this.search});

  Map<String, dynamic> toQuery() {
    final m = <String, dynamic>{};
    if (grade != null) m['grade'] = grade!.toApi();
    if (branch != null) m['branch'] = branch!.toApi();
    if (search != null && search!.trim().isNotEmpty) m['search'] = search!.trim();
    return m;
  }
}

class AdminRepository {
  final Dio _dio;
  AdminRepository(this._dio);

  Future<AdminDashboardStats> dashboard() async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.adminDashboard);
      return AdminDashboardStats.fromJson(
        (res.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<List<StudentAdminRow>> students({AdminStudentFilter filter = const AdminStudentFilter()}) async {
    return runApiCall(() async {
      final res = await _dio.get(
        ApiEndpoints.adminStudents,
        queryParameters: filter.toQuery(),
      );
      final list = (res.data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => StudentAdminRow.fromJson(e.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<StudentSubscription> freeze(String studentId, {required bool freeze, String? reason}) async {
    return runApiCall(() async {
      final res = await _dio.post(
        ApiEndpoints.adminStudentFreeze(studentId),
        data: {'freeze': freeze, 'reason': reason},
      );
      return StudentSubscription.fromJson(
        (res.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<StudentSubscription> grant(String studentId,
      {required PlanType planType,
      int? durationDays,
      List<String>? subjectIds}) async {
    return runApiCall(() async {
      final res = await _dio.post(
        ApiEndpoints.adminStudentGrant(studentId),
        data: {
          'planType': planType.toApi(),
          'durationDays': durationDays,
          'subjectIds': subjectIds,
        },
      );
      return StudentSubscription.fromJson(
        (res.data as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<TeacherListResponse> teachers({String? search, int page = 1, int limit = 10}) async {
    return runApiCall(() async {
      final res = await _dio.get(
        ApiEndpoints.adminTeachers,
        queryParameters: {
          if (search != null) 'search': search,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      return TeacherListResponse.fromJson((res.data as Map).cast<String, dynamic>());
    });
  }

  Future<TeacherDashboardData> teachersDashboard() async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.adminTeachersDashboard);
      return TeacherDashboardData.fromJson(
          (res.data as Map).cast<String, dynamic>());
    });
  }

  Future<CreateTeacherResponse> createTeacher(Map<String, dynamic> data) async {
    return runApiCall(() async {
      final res = await _dio.post(ApiEndpoints.adminTeachers, data: data);
      return CreateTeacherResponse.fromJson(
          (res.data as Map).cast<String, dynamic>());
    });
  }

  Future<List<AdminVideoListItem>> listAdminVideos() async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.adminVideos);
      final list = (res.data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => AdminVideoListItem.fromJson(e.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<void> createAdminVideo(Map<String, dynamic> data) async {
    return runApiCall(() async {
      await _dio.post(ApiEndpoints.adminVideos, data: data);
    });
  }

  Future<void> updateAdminVideo(String id, Map<String, dynamic> data) async {
    return runApiCall(() async {
      await _dio.put(ApiEndpoints.adminVideo(id), data: data);
    });
  }

  Future<void> deleteAdminVideo(String id) async {
    return runApiCall(() async {
      await _dio.delete(ApiEndpoints.adminVideo(id));
    });
  }

  Future<String> uploadFile(String filePath) async {
    return runApiCall(() async {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post(ApiEndpoints.adminUpload, data: formData);
      final data = (res.data as Map).cast<String, dynamic>();
      return data['url']?.toString() ?? '';
    });
  }
}
