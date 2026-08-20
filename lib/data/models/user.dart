import 'api_enums.dart';

class User {
  final String id;
  final String phone;
  final String? name;
  final Grade? grade;
  final Branch? branch;
  final String? parentPhone;
  final UserRole role;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.name,
    this.grade,
    this.branch,
    this.parentPhone,
  });

  bool get needsProfile =>
      role == UserRole.student && (grade == null || branch == null);
  bool get displayNameFirst => name?.isNotEmpty == true;

  String get displayName =>
      (name?.isNotEmpty ?? false) ? name! : phone;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        name: json['name']?.toString(),
        grade: json['grade'] == null ? null : GradeX.fromApi(json['grade'].toString()),
        branch: json['branch'] == null ? null : BranchX.fromApi(json['branch'].toString()),
        parentPhone: json['parentPhone']?.toString(),
        role: UserRoleX.fromApi(json['role']?.toString()),
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'name': name,
    'grade': grade?.toApi(),
    'branch': branch?.toApi(),
    'parentPhone': parentPhone,
    'role': role.toApi(),
    'createdAt': createdAt.toIso8601String(),
  };

  User copyWith({
    String? name,
    Grade? grade,
    Branch? branch,
    String? parentPhone,
  }) =>
      User(
        id: id,
        phone: phone,
        role: role,
        createdAt: createdAt,
        name: name ?? this.name,
        grade: grade ?? this.grade,
        branch: branch ?? this.branch,
        parentPhone: parentPhone ?? this.parentPhone,
      );
}

class StudentSubscription {
  final String id;
  final String userId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isFrozen;
  final String? notes;
  final DateTime createdAt;
  final SubscriptionPlan plan;
  final List<SubscriptionSubject> subjects;

  const StudentSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isFrozen,
    required this.createdAt,
    required this.plan,
    required this.subjects,
    this.notes,
  });

  bool get isEffectivelyActive =>
      isActive && !isFrozen && endDate.isAfter(DateTime.now());

  Duration get remaining {
    final diff = endDate.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  int get remainingDays {
    final days = remaining.inDays;
    return days < 0 ? 0 : days;
  }

  factory StudentSubscription.fromJson(Map<String, dynamic> json) =>
      StudentSubscription(
        id: json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        planId: json['planId']?.toString() ?? '',
        startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ??
            DateTime.now(),
        endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ??
            DateTime.now(),
        isActive: json['isActive'] == true,
        isFrozen: json['isFrozen'] == true,
        notes: json['notes']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        plan: SubscriptionPlan.fromJson(
          (json['plan'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        subjects: (json['subjects'] as List? ?? [])
            .map((e) => SubscriptionSubject.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

class SubscriptionSubject {
  final String id;
  final String subscriptionId;
  final String subjectId;
  final Map<String, dynamic>? subject;

  const SubscriptionSubject({
    required this.id,
    required this.subscriptionId,
    required this.subjectId,
    this.subject,
  });

  factory SubscriptionSubject.fromJson(Map<String, dynamic> json) =>
      SubscriptionSubject(
        id: json['id']?.toString() ?? '',
        subscriptionId: json['subscriptionId']?.toString() ?? '',
        subjectId: json['subjectId']?.toString() ?? '',
        subject: (json['subject'] as Map?)?.cast<String, dynamic>(),
      );
}

class SubscriptionPlan {
  final String id;
  final PlanType type;
  final String nameAr;
  final int durationDays;
  final num discountPercent;
  final num priceIls;
  final int videosPerSubject;
  final bool isActive;
  final DateTime createdAt;

  const SubscriptionPlan({
    required this.id,
    required this.type,
    required this.nameAr,
    required this.durationDays,
    required this.discountPercent,
    required this.priceIls,
    required this.videosPerSubject,
    required this.isActive,
    required this.createdAt,
  });

  num get effectivePrice => priceIls * (1 - discountPercent / 100);

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlan(
        id: json['id']?.toString() ?? '',
        type: PlanTypeX.fromApi(json['type']?.toString()),
        nameAr: json['nameAr']?.toString() ?? '',
        durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
        discountPercent: (json['discountPercent'] as num?) ?? 0,
        priceIls: (json['priceIls'] as num?) ?? 0,
        videosPerSubject: (json['videosPerSubject'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}
