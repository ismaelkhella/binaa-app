import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/cart.dart';

class CartRepository {
  final Dio _dio;
  CartRepository(this._dio);

  Future<CartResponse> getCart() async {
    return runApiCall(() async {
      final res = await _dio.get(ApiEndpoints.cart);
      return CartResponse.fromJson((res.data as Map).cast<String, dynamic>());
    });
  }

  Future<String> addToCart(String subjectId) async {
    return runApiCall(() async {
      final res = await _dio.post(
        ApiEndpoints.addToCart,
        data: {'subjectId': subjectId},
      );
      final data = (res.data as Map).cast<String, dynamic>();
      return data['message']?.toString() ?? 'تمت إضافة المادة للسلة بنجاح';
    });
  }

  Future<String> removeFromCart(String subjectId) async {
    return runApiCall(() async {
      final res = await _dio.delete(ApiEndpoints.removeFromCart(subjectId));
      final data = (res.data as Map).cast<String, dynamic>();
      return data['message']?.toString() ?? 'تم حذف المادة من السلة بنجاح';
    });
  }

  Future<CheckoutResponse> checkout() async {
    return runApiCall(() async {
      final res = await _dio.post(ApiEndpoints.checkout);
      return CheckoutResponse.fromJson(
          (res.data as Map).cast<String, dynamic>());
    });
  }
}
