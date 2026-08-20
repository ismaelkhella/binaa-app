class AdminDashboardStats {
  final StudentStats students;
  final SubscriptionStats subscriptions;
  final RevenueStats revenue;
  final ContentStats content;
  final List<RecentStudent> recentStudents;
  final List<TopVideo> topVideos;

  const AdminDashboardStats({
    required this.students,
    required this.subscriptions,
    required this.revenue,
    required this.content,
    required this.recentStudents,
    required this.topVideos,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> m(String key) =>
        ((json[key] as Map?)?.cast<String, dynamic>()) ?? const {};

    return AdminDashboardStats(
      students: StudentStats.fromJson(m('students')),
      subscriptions: SubscriptionStats.fromJson(m('subscriptions')),
      revenue: RevenueStats.fromJson(m('revenue')),
      content: ContentStats.fromJson(m('content')),
      recentStudents: ((json['recentStudents'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => RecentStudent.fromJson(e.cast<String, dynamic>()))
          .toList(),
      topVideos: ((json['topVideos'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => TopVideo.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class StudentStats {
  final int total;
  final int active;
  final int trial;
  const StudentStats({required this.total, required this.active, required this.trial});

  factory StudentStats.fromJson(Map<String, dynamic> j) => StudentStats(
        total: (j['total'] as num?)?.toInt() ?? 0,
        active: (j['active'] as num?)?.toInt() ?? 0,
        trial: (j['trial'] as num?)?.toInt() ?? 0,
      );
}

class SubscriptionStats {
  final int thisMonth;
  final int lastMonth;
  const SubscriptionStats({required this.thisMonth, required this.lastMonth});

  factory SubscriptionStats.fromJson(Map<String, dynamic> j) =>
      SubscriptionStats(
        thisMonth: (j['thisMonth'] as num?)?.toInt() ?? 0,
        lastMonth: (j['lastMonth'] as num?)?.toInt() ?? 0,
      );
}

class RevenueStats {
  final num thisMonth;
  final String currency;
  const RevenueStats({required this.thisMonth, required this.currency});

  factory RevenueStats.fromJson(Map<String, dynamic> j) => RevenueStats(
        thisMonth: (j['thisMonth'] as num?) ?? 0,
        currency: j['currency']?.toString() ?? 'ILS',
      );
}

class ContentStats {
  final int totalVideos;
  final int completionRate;
  const ContentStats({required this.totalVideos, required this.completionRate});

  factory ContentStats.fromJson(Map<String, dynamic> j) => ContentStats(
        totalVideos: (j['totalVideos'] as num?)?.toInt() ?? 0,
        completionRate: (j['completionRate'] as num?)?.toInt() ?? 0,
      );
}

class RecentStudent {
  final String id;
  final String phone;
  final String? name;
  final DateTime createdAt;
  const RecentStudent({
    required this.id,
    required this.phone,
    required this.createdAt,
    this.name,
  });

  factory RecentStudent.fromJson(Map<String, dynamic> json) => RecentStudent(
        id: json['id']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        name: json['name']?.toString(),
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class TopVideo {
  final String videoId;
  final String title;
  final String subject;
  final int views;
  const TopVideo({
    required this.videoId,
    required this.title,
    required this.subject,
    required this.views,
  });

  factory TopVideo.fromJson(Map<String, dynamic> json) => TopVideo(
        videoId: json['videoId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        views: (json['views'] as num?)?.toInt() ?? 0,
      );
}

class StudentAdminRow {
  final String id;
  final String phone;
  final String? name;
  final String? grade; // raw API string
  final String? branch; // raw API string
  final String? parentPhone;
  final bool isActive;
  final DateTime createdAt;
  final int viewsCount;
  final AdminSubscriptionSummary? subscription;

  const StudentAdminRow({
    required this.id,
    required this.phone,
    required this.isActive,
    required this.createdAt,
    required this.viewsCount,
    this.name,
    this.grade,
    this.branch,
    this.parentPhone,
    this.subscription,
  });

  factory StudentAdminRow.fromJson(Map<String, dynamic> json) =>
      StudentAdminRow(
        id: json['id']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        name: json['name']?.toString(),
        grade: json['grade']?.toString(),
        branch: json['branch']?.toString(),
        parentPhone: json['parentPhone']?.toString(),
        isActive: json['isActive'] == true,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
        subscription: json['subscription'] == null
            ? null
            : AdminSubscriptionSummary.fromJson(
                (json['subscription'] as Map).cast<String, dynamic>(),
              ),
      );
}

class AdminSubscriptionSummary {
  final String planType;
  final String planName;
  final DateTime endDate;
  final bool isFrozen;

  const AdminSubscriptionSummary({
    required this.planType,
    required this.planName,
    required this.endDate,
    required this.isFrozen,
  });

  factory AdminSubscriptionSummary.fromJson(Map<String, dynamic> json) =>
      AdminSubscriptionSummary(
        planType: json['planType']?.toString() ?? '',
        planName: json['planName']?.toString() ?? '',
        endDate:
            DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
        isFrozen: json['isFrozen'] == true,
      );
}

class Teacher {
  final String id;
  final String userId;
  final String name;
  final String? bio;
  final num commissionRate;
  final DateTime createdAt;
  final String? phone;
  final String? email;
  final String? specialty;
  final String? grade;
  final int lessons;
  final num rating;
  final String? status;
  final String? avatar;
  final int subjectCount;
  final int videoCount;

  const Teacher({
    required this.id,
    required this.userId,
    required this.name,
    required this.commissionRate,
    required this.createdAt,
    required this.lessons,
    required this.rating,
    required this.subjectCount,
    required this.videoCount,
    this.bio,
    this.phone,
    this.email,
    this.specialty,
    this.grade,
    this.status,
    this.avatar,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>();
    final counts = (json['_count'] as Map?)?.cast<String, dynamic>();

    return Teacher(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bio: json['bio']?.toString(),
      commissionRate: (json['commissionRate'] as num?) ?? 0.0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      phone: user?['phone']?.toString(),
      email: json['email']?.toString(),
      specialty: json['specialty']?.toString(),
      grade: json['grade']?.toString(),
      lessons: (json['lessons'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?) ?? 0.0,
      status: json['status']?.toString(),
      avatar: json['avatar']?.toString(),
      subjectCount: (counts?['subjects'] as num?)?.toInt() ?? 0,
      videoCount: (counts?['videos'] as num?)?.toInt() ?? 0,
    );
  }
}

class TeacherDashboardData {
  final TeacherStats stats;
  final List<TeacherApplication> applications;
  final List<TopTeacher> topTeachers;

  const TeacherDashboardData({
    required this.stats,
    required this.applications,
    required this.topTeachers,
  });

  factory TeacherDashboardData.fromJson(Map<String, dynamic> json) =>
      TeacherDashboardData(
        stats: TeacherStats.fromJson(
            (json['stats'] as Map).cast<String, dynamic>()),
        applications: (json['applications'] as List? ?? [])
            .map((e) => TeacherApplication.fromJson(e.cast<String, dynamic>()))
            .toList(),
        topTeachers: (json['topTeachers'] as List? ?? [])
            .map((e) => TopTeacher.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

class TeacherStats {
  final int totalTeachers;
  final int activeClasses;
  final num performanceRating;
  final int contentHours;

  const TeacherStats({
    required this.totalTeachers,
    required this.activeClasses,
    required this.performanceRating,
    required this.contentHours,
  });

  factory TeacherStats.fromJson(Map<String, dynamic> json) => TeacherStats(
        totalTeachers: (json['totalTeachers'] as num?)?.toInt() ?? 0,
        activeClasses: (json['activeClasses'] as num?)?.toInt() ?? 0,
        performanceRating: (json['performanceRating'] as num?) ?? 0.0,
        contentHours: (json['contentHours'] as num?)?.toInt() ?? 0,
      );
}

class TeacherApplication {
  final String id;
  final String name;
  final String title;
  final String timeText;

  const TeacherApplication({
    required this.id,
    required this.name,
    required this.title,
    required this.timeText,
  });

  factory TeacherApplication.fromJson(Map<String, dynamic> json) =>
      TeacherApplication(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        timeText: json['timeText']?.toString() ?? '',
      );
}

class TopTeacher {
  final String id;
  final String name;
  final int satisfactionRate;
  final String? avatar;

  const TopTeacher({
    required this.id,
    required this.name,
    required this.satisfactionRate,
    this.avatar,
  });

  factory TopTeacher.fromJson(Map<String, dynamic> json) => TopTeacher(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        satisfactionRate: (json['satisfactionRate'] as num?)?.toInt() ?? 0,
        avatar: json['avatar']?.toString(),
      );
}

class TeacherListResponse {
  final List<Teacher> teachers;
  final int total;
  final int page;
  final int limit;

  const TeacherListResponse({
    required this.teachers,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory TeacherListResponse.fromJson(Map<String, dynamic> json) =>
      TeacherListResponse(
        teachers: (json['teachers'] as List? ?? [])
            .map((e) => Teacher.fromJson(e.cast<String, dynamic>()))
            .toList(),
        total: (json['total'] as num?)?.toInt() ?? 0,
        page: (json['page'] as num?)?.toInt() ?? 1,
        limit: (json['limit'] as num?)?.toInt() ?? 10,
      );
}

class AdminVideoListItem {
  final String id;
  final String subjectId;
  final String? teacherId;
  final String title;
  final String? description;
  final String? streamUrl;
  final String? pdfUrl;
  final int durationSec;
  final int unitNumber;
  final int orderInUnit;
  final int maxViews;
  final int downloadDays;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AdminVideoSubject subject;
  final AdminVideoTeacher? teacher;
  final int videoViewsCount;

  const AdminVideoListItem({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.durationSec,
    required this.unitNumber,
    required this.orderInUnit,
    required this.maxViews,
    required this.downloadDays,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.subject,
    required this.videoViewsCount,
    this.teacherId,
    this.description,
    this.streamUrl,
    this.pdfUrl,
    this.teacher,
  });

  factory AdminVideoListItem.fromJson(Map<String, dynamic> json) {
    final counts = (json['_count'] as Map?)?.cast<String, dynamic>();
    return AdminVideoListItem(
      id: json['id']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      teacherId: json['teacherId']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      streamUrl: json['streamUrl']?.toString(),
      pdfUrl: json['pdfUrl']?.toString(),
      durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
      unitNumber: (json['unitNumber'] as num?)?.toInt() ?? 0,
      orderInUnit: (json['orderInUnit'] as num?)?.toInt() ?? 0,
      maxViews: (json['maxViews'] as num?)?.toInt() ?? 0,
      downloadDays: (json['downloadDays'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'DRAFT',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      subject: AdminVideoSubject.fromJson(
          (json['subject'] as Map).cast<String, dynamic>()),
      teacher: json['teacher'] == null
          ? null
          : AdminVideoTeacher.fromJson(
              (json['teacher'] as Map).cast<String, dynamic>()),
      videoViewsCount: (counts?['videoViews'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminVideoSubject {
  final String name;
  final String grade;
  final String branch;
  const AdminVideoSubject(
      {required this.name, required this.grade, required this.branch});
  factory AdminVideoSubject.fromJson(Map<String, dynamic> json) =>
      AdminVideoSubject(
        name: json['name']?.toString() ?? '',
        grade: json['grade']?.toString() ?? '',
        branch: json['branch']?.toString() ?? '',
      );
}

class AdminVideoTeacher {
  final String name;
  const AdminVideoTeacher({required this.name});
  factory AdminVideoTeacher.fromJson(Map<String, dynamic> json) =>
      AdminVideoTeacher(
        name: json['name']?.toString() ?? '',
      );
}

class CreateTeacherResponse {
  final String id;
  final String userId;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final num commissionRate;
  final DateTime createdAt;
  final String? phone;
  final List<CreateTeacherSubject> subjects;

  const CreateTeacherResponse({
    required this.id,
    required this.userId,
    required this.name,
    required this.commissionRate,
    required this.createdAt,
    required this.subjects,
    this.bio,
    this.avatarUrl,
    this.phone,
  });

  factory CreateTeacherResponse.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?)?.cast<String, dynamic>();
    return CreateTeacherResponse(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bio: json['bio']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      commissionRate: (json['commissionRate'] as num?) ?? 0.0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      phone: user?['phone']?.toString(),
      subjects: (json['subjects'] as List? ?? [])
          .map((e) => CreateTeacherSubject.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class CreateTeacherSubject {
  final String id;
  final String name;
  const CreateTeacherSubject({required this.id, required this.name});
  factory CreateTeacherSubject.fromJson(Map<String, dynamic> json) =>
      CreateTeacherSubject(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}
