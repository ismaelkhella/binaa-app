import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/cache_storage.dart';
import '../models/student_stats.dart';
import '../models/user.dart';

class MeData {
  final User user;
  final Subscription? subscription;
  const MeData({required this.user, this.subscription});

  factory MeData.fromJson(Map<String, dynamic> data) {
    final sub = data['subscription'];
    return MeData(
      user: User.fromJson(data),
      subscription: sub == null
          ? null
          : Subscription.fromJson((sub as Map).cast<String, dynamic>()),
    );
  }
}

class Subscription {
  final String planType;
  final String planName;
  final DateTime endDate;
  final bool isActive;
  final int videosPerSubject;
  const Subscription({
    required this.planType,
    required this.planName,
    required this.endDate,
    required this.isActive,
    required this.videosPerSubject,
  });

  Map<String, dynamic> toJson() => {
    'planType': planType,
    'planName': planName,
    'endDate': endDate.toIso8601String(),
    'isActive': isActive,
    'videosPerSubject': videosPerSubject,
  };

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        planType: j['planType']?.toString() ?? '',
        planName: j['planName']?.toString() ?? '',
        endDate: DateTime.tryParse(j['endDate']?.toString() ?? '') ??
            DateTime.now(),
        isActive: j['isActive'] == true,
        videosPerSubject: (j['videosPerSubject'] as num?)?.toInt() ?? 0,
      );
}

class UserRepository {
  final Dio _dio;
  final CacheStorage _cache;
  UserRepository(this._dio, this._cache);

  Future<MeData> getMe() async {
    try {
      final res = await _dio.get(ApiEndpoints.me);
      final data = (res.data as Map).cast<String, dynamic>();
      await _cache.saveMe(data);
      return MeData.fromJson(data);
    } catch (e) {
      final cached = await _cache.getMe();
      if (cached != null) {
        debugPrint('UserRepository: Loading "me" from cache');
        return MeData.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<String> updateParentPhone(String phone) async {
    return runApiCall(() async {
      final res = await _dio.put(
        ApiEndpoints.updateParentPhone,
        data: {'parentPhone': phone},
      );
      final data = (res.data as Map).cast<String, dynamic>();
      return data['parentPhone']?.toString() ?? phone;
    });
  }

  Future<DashboardData> getDashboard() async {
    try {
      final res = await _dio.get(ApiEndpoints.dashboard);
      final data = (res.data as Map).cast<String, dynamic>();
      await _cache.saveDashboard(data);
      return DashboardData.fromJson(data);
    } catch (e) {
      final cached = await _cache.getDashboard();
      if (cached != null) {
        debugPrint('UserRepository: Loading dashboard from cache');
        return DashboardData.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<PerformanceData> getPerformance() async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.performance);
      return PerformanceData.fromJson((res.data as Map).cast<String, dynamic>());
    });
  }

  Future<Map<String, List<DailyGoal>>> listGoals() async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.goals);
      final data = (res.data as Map).cast<String, dynamic>();
      return {
        'today': (data['today'] as List? ?? [])
            .map((e) => DailyGoal.fromJson(e.cast<String, dynamic>()))
            .toList(),
        'archived': (data['archived'] as List? ?? [])
            .map((e) => DailyGoal.fromJson(e.cast<String, dynamic>()))
            .toList(),
      };
    });
  }

  Future<DailyGoal> createGoal(String title) async {
    return runApiCall(() async {
      final res = await _dio.post(ApiEndpoints.goals, data: {'title': title});
      return DailyGoal.fromJson((res.data as Map).cast<String, dynamic>());
    });
  }

  Future<DailyGoal> updateGoal(String id,
      {bool? completed, String? title}) async {
    return runApiCall(() async {
      final res = await _dio.patch(
        ApiEndpoints.goal(id),
        data: {
          if (completed != null) 'completed': completed,
          if (title != null) 'title': title,
        },
      );
      return DailyGoal.fromJson((res.data as Map).cast<String, dynamic>());
    });
  }

  Future<void> deleteGoal(String id) async {
    return runApiCall(() async {
      await _dio.delete(ApiEndpoints.goal(id));
    });
  }
}
