import 'api_enums.dart';
import 'student_stats.dart';

class Subject {
  final String id;
  final String name;
  final Grade grade;
  final Branch branch;
  final String? teacherName;
  final int videoCount;
  final int progressPercent;
  final bool locked;
  final double priceIls;
  final DateTime createdAt;

  const Subject({
    required this.id,
    required this.name,
    required this.grade,
    required this.branch,
    required this.videoCount,
    required this.progressPercent,
    required this.locked,
    required this.priceIls,
    required this.createdAt,
    this.teacherName,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        grade: GradeX.fromApi(json['grade']?.toString()),
        branch: BranchX.fromApi(json['branch']?.toString()),
        teacherName: json['teacherName']?.toString(),
        videoCount: (json['videoCount'] as num?)?.toInt() ?? 0,
        progressPercent: (json['progressPercent'] as num?)?.toInt() ?? 0,
        locked: json['locked'] == true,
        priceIls: (json['priceIls'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'grade': grade.toApi(),
    'branch': branch.toApi(),
    'teacherName': teacherName,
    'videoCount': videoCount,
    'progressPercent': progressPercent,
    'locked': locked,
    'priceIls': priceIls,
    'createdAt': createdAt.toIso8601String(),
  };
}

class SubjectVideoItem {
  final String id;
  final String title;
  final String? description;
  final int durationSec;
  final int unitNumber;
  final int orderInUnit;
  final bool locked;
  final bool? _isCompleted;
  bool get isCompleted => _isCompleted ?? false;

  const SubjectVideoItem({
    required this.id,
    required this.title,
    required this.durationSec,
    required this.unitNumber,
    required this.orderInUnit,
    required this.locked,
    bool? isCompleted,
    this.description,
  }) : _isCompleted = isCompleted;

  factory SubjectVideoItem.fromJson(Map<String, dynamic> json) =>
      SubjectVideoItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
        unitNumber: (json['unitNumber'] as num?)?.toInt() ?? 1,
        orderInUnit: (json['orderInUnit'] as num?)?.toInt() ?? 1,
        locked: json['locked'] == true,
        isCompleted: json['isCompleted'] == true,
      );
}

class SubjectVideosResponse {
  final SubjectLite subject;
  final int quota;
  final List<SubjectVideoItem> videos;
  final DailyQuiz? dailyQuiz;

  const SubjectVideosResponse({
    required this.subject,
    required this.quota,
    required this.videos,
    this.dailyQuiz,
  });

  factory SubjectVideosResponse.fromJson(Map<String, dynamic> json) {
    final videosJson = (json['videos'] as List?) ?? const [];
    return SubjectVideosResponse(
      subject: SubjectLite.fromJson(
        (json['subject'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      quota: (json['quota'] as num?)?.toInt() ?? 0,
      videos: videosJson
          .whereType<Map>()
          .map((e) => SubjectVideoItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      dailyQuiz: json['dailyQuiz'] == null
          ? null
          : DailyQuiz.fromJson(
              (json['dailyQuiz'] as Map).cast<String, dynamic>()),
    );
  }
}

class SubjectLite {
  final String id;
  final String name;

  const SubjectLite({required this.id, required this.name});

  factory SubjectLite.fromJson(Map<String, dynamic> json) =>
      SubjectLite(id: json['id']?.toString() ?? '', name: json['name']?.toString() ?? '');
}
