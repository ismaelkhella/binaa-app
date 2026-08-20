import 'api_enums.dart';

class CartItem {
  final String id;
  final String subjectId;
  final String name;
  final Grade grade;
  final Branch branch;
  final double priceIls;
  final String? teacherName;

  const CartItem({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.grade,
    required this.branch,
    required this.priceIls,
    this.teacherName,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id']?.toString() ?? '',
        subjectId: json['subjectId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        grade: GradeX.fromApi(json['grade']?.toString()),
        branch: BranchX.fromApi(json['branch']?.toString()),
        priceIls: (json['priceIls'] as num?)?.toDouble() ?? 0.0,
        teacherName: json['teacherName']?.toString(),
      );
}

class CartResponse {
  final List<CartItem> items;
  final double totalPriceIls;

  const CartResponse({
    required this.items,
    required this.totalPriceIls,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) => CartResponse(
        items: (json['items'] as List? ?? [])
            .map((e) => CartItem.fromJson(e.cast<String, dynamic>()))
            .toList(),
        totalPriceIls: (json['totalPriceIls'] as num?)?.toDouble() ?? 0.0,
      );
}

class CheckoutResponse {
  final String message;
  final double totalPriceIls;
  final String subscriptionId;
  final DateTime endDate;
  final List<String> subjects;

  const CheckoutResponse({
    required this.message,
    required this.totalPriceIls,
    required this.subscriptionId,
    required this.endDate,
    required this.subjects,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) =>
      CheckoutResponse(
        message: json['message']?.toString() ?? '',
        totalPriceIls: (json['totalPriceIls'] as num?)?.toDouble() ?? 0.0,
        subscriptionId: json['subscriptionId']?.toString() ?? '',
        endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ??
            DateTime.now(),
        subjects: (json['subjects'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
