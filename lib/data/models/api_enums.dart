// Mirror the API's string enums. We use Dart enums for type-safe UI but keep
// the raw string for round-tripping.

enum UserRole { student, teacher, admin }

extension UserRoleX on UserRole {
  String toApi() => switch (this) {
        UserRole.student => 'STUDENT',
        UserRole.teacher => 'TEACHER',
        UserRole.admin => 'ADMIN',
      };

  static UserRole fromApi(String? raw) => switch (raw) {
        'STUDENT' => UserRole.student,
        'TEACHER' => UserRole.teacher,
        'ADMIN' => UserRole.admin,
        _ => UserRole.student,
      };

  String get labelAr => switch (this) {
        UserRole.student => 'طالب',
        UserRole.teacher => 'معلم',
        UserRole.admin => 'إداري',
      };
}

enum Grade { eleven, twelve }

extension GradeX on Grade {
  String toApi() => switch (this) {
        Grade.eleven => 'GRADE_11',
        Grade.twelve => 'GRADE_12',
      };

  static Grade fromApi(String? raw) => switch (raw) {
        'GRADE_11' => Grade.eleven,
        'GRADE_12' => Grade.twelve,
        _ => Grade.twelve,
      };

  String get labelAr => switch (this) {
        Grade.eleven => 'الحادي عشر',
        Grade.twelve => 'الثاني عشر',
      };
}

enum Branch { scientific, literary }

extension BranchX on Branch {
  String toApi() => switch (this) {
        Branch.scientific => 'SCIENTIFIC',
        Branch.literary => 'LITERARY',
      };

  static Branch fromApi(String? raw) => switch (raw) {
        'SCIENTIFIC' => Branch.scientific,
        'LITERARY' => Branch.literary,
        _ => Branch.scientific,
      };

  String get labelAr => switch (this) {
        Branch.scientific => 'الفرع العلمي',
        Branch.literary => 'الفرع الأدبي',
      };

  String get shortAr => switch (this) {
        Branch.scientific => 'علمي',
        Branch.literary => 'أدبي',
      };
}

enum PlanType { trial, monthly, quarterly, yearly }

extension PlanTypeX on PlanType {
  String toApi() => switch (this) {
        PlanType.trial => 'TRIAL',
        PlanType.monthly => 'MONTHLY',
        PlanType.quarterly => 'QUARTERLY',
        PlanType.yearly => 'YEARLY',
      };

  static PlanType fromApi(String? raw) => switch (raw) {
        'TRIAL' => PlanType.trial,
        'MONTHLY' => PlanType.monthly,
        'QUARTERLY' => PlanType.quarterly,
        'YEARLY' => PlanType.yearly,
        _ => PlanType.monthly,
      };
}

enum VideoStatus { draft, pendingReview, published }

extension VideoStatusX on VideoStatus {
  static VideoStatus fromApi(String? raw) => switch (raw) {
        'DRAFT' => VideoStatus.draft,
        'PENDING_REVIEW' => VideoStatus.pendingReview,
        'PUBLISHED' => VideoStatus.published,
        _ => VideoStatus.published,
      };

  String get labelAr => switch (this) {
        VideoStatus.draft => 'مسودة',
        VideoStatus.pendingReview => 'قيد المراجعة',
        VideoStatus.published => 'منشور',
      };
}
