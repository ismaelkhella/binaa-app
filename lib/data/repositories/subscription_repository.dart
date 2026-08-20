import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/user.dart';

class SubscriptionRepository {
  final Dio _dio;
  SubscriptionRepository(this._dio);

  Future<List<SubscriptionPlan>> listPlans() async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.subscriptionPlans);
      final list = (res.data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => SubscriptionPlan.fromJson(e.cast<String, dynamic>()))
          .toList();
    });
  }

  Future<StudentSubscription?> currentSubscription() async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.mySubscription);
      final data = res.data;
      if (data == null) return null;
      if (data is Map<String, dynamic>) return StudentSubscription.fromJson(data);
      return null;
    });
  }
}
