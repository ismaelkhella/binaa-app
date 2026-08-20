class TeacherProfile {
  final String id;
  final String name;
  final String? bio;
  final String? avatarUrl;

  const TeacherProfile({
    required this.id,
    required this.name,
    this.bio,
    this.avatarUrl,
  });

  factory TeacherProfile.fromJson(Map<String, dynamic> json) => TeacherProfile(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        bio: json['bio']?.toString(),
        avatarUrl: json['avatarUrl']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bio': bio,
        'avatarUrl': avatarUrl,
      };
}

class TeacherDashboard {
  final TeacherProfile teacher;
  final int studentsCount;
  final int subjectsCount;
  final int videosCount;
  final double engagementRate;

  const TeacherDashboard({
    required this.teacher,
    required this.studentsCount,
    required this.subjectsCount,
    required this.videosCount,
    required this.engagementRate,
  });

  factory TeacherDashboard.fromJson(Map<String, dynamic> json) =>
      TeacherDashboard(
        teacher: TeacherProfile.fromJson(
            (json['teacher'] as Map).cast<String, dynamic>()),
        studentsCount: (json['studentsCount'] as num?)?.toInt() ?? 0,
        subjectsCount: (json['subjectsCount'] as num?)?.toInt() ?? 0,
        videosCount: (json['videosCount'] as num?)?.toInt() ?? 0,
        engagementRate: (json['engagementRate'] as num?)?.toDouble() ?? 0.0,
      );
}
