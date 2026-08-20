import 'api_enums.dart';

class DashboardData {
  final String studentName;
  final int generalProgress;
  final ContinueLearning? continueLearning;
  final TodayGoals todayGoals;
  final DailyQuiz dailyQuiz;
  final List<SuggestedSubject> suggestedSubjects;
  final List<SubjectShoppingItem> subjectShopping;

  const DashboardData({
    required this.studentName,
    required this.generalProgress,
    this.continueLearning,
    required this.todayGoals,
    required this.dailyQuiz,
    required this.suggestedSubjects,
    required this.subjectShopping,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        studentName: json['studentName']?.toString() ?? '',
        generalProgress: (json['generalProgress'] as num?)?.toInt() ?? 0,
        continueLearning: json['continueLearning'] == null
            ? null
            : ContinueLearning.fromJson(
                (json['continueLearning'] as Map).cast<String, dynamic>()),
        todayGoals: TodayGoals.fromJson(
            (json['todayGoals'] as Map).cast<String, dynamic>()),
        dailyQuiz: DailyQuiz.fromJson(
            (json['dailyQuiz'] as Map).cast<String, dynamic>()),
        suggestedSubjects: (json['suggestedSubjects'] as List? ?? [])
            .map((e) => SuggestedSubject.fromJson(e.cast<String, dynamic>()))
            .toList(),
        subjectShopping: (json['subjectShopping'] as List? ?? [])
            .map((e) => SubjectShoppingItem.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

class SubjectShoppingItem {
  final String id;
  final String name;
  final double priceIls;
  final bool isSubscribed;
  final bool isInCart;
  final ShoppingTeacher? teacher;

  const SubjectShoppingItem({
    required this.id,
    required this.name,
    required this.priceIls,
    required this.isSubscribed,
    required this.isInCart,
    this.teacher,
  });

  factory SubjectShoppingItem.fromJson(Map<String, dynamic> json) =>
      SubjectShoppingItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        priceIls: (json['priceIls'] as num?)?.toDouble() ?? 0.0,
        isSubscribed: json['isSubscribed'] == true,
        isInCart: json['isInCart'] == true,
        teacher: json['teacher'] == null
            ? null
            : ShoppingTeacher.fromJson(
                (json['teacher'] as Map).cast<String, dynamic>()),
      );
}

class ShoppingTeacher {
  final String id;
  final String name;
  final String? avatarUrl;
  final double? rating;

  const ShoppingTeacher({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.rating,
  });

  factory ShoppingTeacher.fromJson(Map<String, dynamic> json) =>
      ShoppingTeacher(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString(),
        rating: (json['rating'] as num?)?.toDouble(),
      );
}

class ContinueLearning {
  final String videoId;
  final String videoTitle;
  final String subjectName;
  final String? unitName;
  final String? lessonText;
  final int durationSec;
  final int timeLeftMin;
  final int progressPercent;

  const ContinueLearning({
    required this.videoId,
    required this.videoTitle,
    required this.subjectName,
    this.unitName,
    this.lessonText,
    required this.durationSec,
    required this.timeLeftMin,
    required this.progressPercent,
  });

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'videoTitle': videoTitle,
        'subjectName': subjectName,
        'unitName': unitName,
        'lessonText': lessonText,
        'durationSec': durationSec,
        'timeLeftMin': timeLeftMin,
        'progressPercent': progressPercent,
      };

  factory ContinueLearning.fromJson(Map<String, dynamic> json) =>
      ContinueLearning(
        videoId: json['videoId']?.toString() ?? '',
        videoTitle: json['videoTitle']?.toString() ?? '',
        subjectName: json['subjectName']?.toString() ?? '',
        unitName: json['unitName']?.toString(),
        lessonText: json['lessonText']?.toString(),
        durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
        timeLeftMin: (json['timeLeftMin'] as num?)?.toInt() ?? 0,
        progressPercent: (json['progressPercent'] as num?)?.toInt() ?? 0,
      );
}

class TodayGoals {
  final int completedCount;
  final int totalCount;
  final int percentage;
  final String text;

  const TodayGoals({
    required this.completedCount,
    required this.totalCount,
    required this.percentage,
    required this.text,
  });

  factory TodayGoals.fromJson(Map<String, dynamic> json) => TodayGoals(
        completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
        totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toInt() ?? 0,
        text: json['text']?.toString() ?? '',
      );
}

class DailyQuiz {
  final String id;
  final String title;
  final String description;
  final bool isAvailable;
  final String buttonText;
  final int points;

  const DailyQuiz({
    required this.id,
    required this.title,
    required this.description,
    required this.isAvailable,
    required this.buttonText,
    required this.points,
  });

  factory DailyQuiz.fromJson(Map<String, dynamic> json) => DailyQuiz(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        isAvailable: json['isAvailable'] == true,
        buttonText: json['buttonText']?.toString() ?? '',
        points: (json['points'] as num?)?.toInt() ?? 0,
      );
}

class SuggestedSubject {
  final String id;
  final String subjectName;
  final String teacherName;
  final double? rating;

  const SuggestedSubject({
    required this.id,
    required this.subjectName,
    required this.teacherName,
    this.rating,
  });

  factory SuggestedSubject.fromJson(Map<String, dynamic> json) {
    final ratingValue = json['rating'];
    double? parsedRating;
    if (ratingValue is num) {
      parsedRating = ratingValue.toDouble();
    } else if (ratingValue is String) {
      parsedRating = double.tryParse(ratingValue);
    }

    return SuggestedSubject(
      id: json['id']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      teacherName: json['teacherName']?.toString() ?? '',
      rating: parsedRating,
    );
  }
}

class DailyGoal {
  final String id;
  final String title;
  final bool completed;
  final DateTime dueDate;

  const DailyGoal({
    required this.id,
    required this.title,
    required this.completed,
    required this.dueDate,
  });

  factory DailyGoal.fromJson(Map<String, dynamic> json) => DailyGoal(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        completed: json['completed'] == true,
        dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class PerformanceData {
  final int goalsAchievementPercent;
  final int peerComparisonPercent;
  final List<WeeklyStudyHours> weeklyStudyHours;
  final List<SubjectProgress> subjectProgress;
  final List<RecentQuiz> recentQuizzes;

  const PerformanceData({
    required this.goalsAchievementPercent,
    required this.peerComparisonPercent,
    required this.weeklyStudyHours,
    required this.subjectProgress,
    required this.recentQuizzes,
  });

  factory PerformanceData.fromJson(Map<String, dynamic> json) => PerformanceData(
        goalsAchievementPercent:
            (json['goalsAchievementPercent'] as num?)?.toInt() ?? 0,
        peerComparisonPercent:
            (json['peerComparisonPercent'] as num?)?.toInt() ?? 0,
        weeklyStudyHours: (json['weeklyStudyHours'] as List? ?? [])
            .map((e) => WeeklyStudyHours.fromJson(e.cast<String, dynamic>()))
            .toList(),
        subjectProgress: (json['subjectProgress'] as List? ?? [])
            .map((e) => SubjectProgress.fromJson(e.cast<String, dynamic>()))
            .toList(),
        recentQuizzes: (json['recentQuizzes'] as List? ?? [])
            .map((e) => RecentQuiz.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

class WeeklyStudyHours {
  final String day;
  final double hours;

  const WeeklyStudyHours({required this.day, required this.hours});

  factory WeeklyStudyHours.fromJson(Map<String, dynamic> json) =>
      WeeklyStudyHours(
        day: json['day']?.toString() ?? '',
        hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
      );
}

class SubjectProgress {
  final String subjectName;
  final int progressPercent;

  const SubjectProgress({
    required this.subjectName,
    required this.progressPercent,
  });

  factory SubjectProgress.fromJson(Map<String, dynamic> json) =>
      SubjectProgress(
        subjectName: json['subjectName']?.toString() ?? '',
        progressPercent: (json['progressPercent'] as num?)?.toInt() ?? 0,
      );
}

class RecentQuiz {
  final String title;
  final int score;
  final int totalQuestions;
  final String dateText;

  const RecentQuiz({
    required this.title,
    required this.score,
    required this.totalQuestions,
    required this.dateText,
  });

  factory RecentQuiz.fromJson(Map<String, dynamic> json) => RecentQuiz(
        title: json['title']?.toString() ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
        dateText: json['dateText']?.toString() ?? '',
      );
}
