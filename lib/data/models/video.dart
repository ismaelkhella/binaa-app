class WatermarkInfo {
  final String name;
  final String phone;
  const WatermarkInfo({required this.name, required this.phone});

  factory WatermarkInfo.fromJson(Map<String, dynamic> json) => WatermarkInfo(
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
      );

  String get display =>
      '${name.isNotEmpty ? name : phone} • ${_maskPhone(phone)}';

  static String _maskPhone(String phone) {
    if (phone.length < 5) return phone;
    final visible = phone.substring(phone.length - 2);
    return '••• $visible';
  }
}

class StreamTokenResponse {
  final String? streamUrl;
  final WatermarkInfo watermark;
  final List<double> playbackRates;
  final List<String> qualities;

  const StreamTokenResponse({
    required this.streamUrl,
    required this.watermark,
    required this.playbackRates,
    required this.qualities,
  });

  factory StreamTokenResponse.fromJson(Map<String, dynamic> json) {
    final ratesJson = (json['playbackRates'] as List?) ?? const [1];
    return StreamTokenResponse(
      streamUrl: json['streamUrl']?.toString(),
      watermark: WatermarkInfo.fromJson(
        (json['watermark'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      playbackRates: ratesJson.whereType<num>().map((e) => e.toDouble()).toList(),
      qualities: ((json['qualities'] as List?) ?? const ['auto'])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class VideoViewTracker {
  final int viewCount;
  final int maxViews;
  final TriggerQuiz? triggerQuiz;

  const VideoViewTracker({
    required this.viewCount,
    required this.maxViews,
    this.triggerQuiz,
  });

  factory VideoViewTracker.fromJson(Map<String, dynamic> json) =>
      VideoViewTracker(
        viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
        maxViews: (json['maxViews'] as num?)?.toInt() ?? 3,
        triggerQuiz: json['triggerQuiz'] == null
            ? null
            : TriggerQuiz.fromJson(
                (json['triggerQuiz'] as Map).cast<String, dynamic>()),
      );
}

class TriggerQuiz {
  final String title;
  final String subjectId;
  final List<QuizQuestion> questions;

  const TriggerQuiz({
    required this.title,
    required this.subjectId,
    required this.questions,
  });

  factory TriggerQuiz.fromJson(Map<String, dynamic> json) => TriggerQuiz(
        title: json['title']?.toString() ?? '',
        subjectId: json['subjectId']?.toString() ?? '',
        questions: (json['questions'] as List? ?? [])
            .map((e) => QuizQuestion.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

class QuizQuestion {
  final String id;
  final String text;
  final List<String> options;
  final String answer;

  const QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.answer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: json['id']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        options: (json['options'] as List? ?? []).map((e) => e.toString()).toList(),
        answer: json['answer']?.toString() ?? '',
      );
}

class DownloadToken {
  final String token;
  final DateTime expiresAt;
  final int downloadDays;

  const DownloadToken({
    required this.token,
    required this.expiresAt,
    required this.downloadDays,
  });

  factory DownloadToken.fromJson(Map<String, dynamic> json) => DownloadToken(
        token: json['token']?.toString() ?? '',
        expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
            DateTime.now(),
        downloadDays: (json['downloadDays'] as num?)?.toInt() ?? 7,
      );
}

enum ChapterStatus { COMPLETED, PLAYING, UNPLAYED, LOCKED }

class LessonChapter {
  final String id;
  final String title;
  final int startSec;
  final int endSec;
  final String durationText;
  final ChapterStatus status;

  const LessonChapter({
    required this.id,
    required this.title,
    required this.startSec,
    required this.endSec,
    required this.durationText,
    required this.status,
  });

  factory LessonChapter.fromJson(Map<String, dynamic> json) => LessonChapter(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        startSec: (json['startSec'] as num?)?.toInt() ?? 0,
        endSec: (json['endSec'] as num?)?.toInt() ?? 0,
        durationText: json['durationText']?.toString() ?? '',
        status: ChapterStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ChapterStatus.UNPLAYED,
        ),
      );
}

class RelatedVideo {
  final String id;
  final String title;
  final String subjectName;
  final String? teacherName;
  final String durationText;
  final String unitName;

  const RelatedVideo({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.durationText,
    required this.unitName,
    this.teacherName,
  });

  factory RelatedVideo.fromJson(Map<String, dynamic> json) => RelatedVideo(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        subjectName: json['subjectName']?.toString() ?? '',
        teacherName: json['teacherName']?.toString(),
        durationText: json['durationText']?.toString() ?? '',
        unitName: json['unitName']?.toString() ?? '',
      );
}

class LessonVideoDetail {
  final String id;
  final String title;
  final String? description;
  final String? streamUrl;
  final String? pdfUrl;
  final int durationSec;
  final String unitName;
  final String subHeader;
  final String? teacherName;
  final String? dailyQuizId;
  final List<QuizQuestion> questions;
  final bool? _isCompleted;
  bool get isCompleted => _isCompleted ?? false;

  const LessonVideoDetail({
    required this.id,
    required this.title,
    required this.durationSec,
    required this.unitName,
    required this.subHeader,
    required this.questions,
    bool? isCompleted,
    this.description,
    this.streamUrl,
    this.pdfUrl,
    this.teacherName,
    this.dailyQuizId,
  }) : _isCompleted = isCompleted;

  factory LessonVideoDetail.fromJson(Map<String, dynamic> json) {
    return LessonVideoDetail(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      streamUrl: json['streamUrl']?.toString(),
      pdfUrl: json['pdfUrl']?.toString(),
      durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
      unitName: json['unitName']?.toString() ?? '',
      subHeader: json['subHeader']?.toString() ?? '',
      teacherName: json['teacherName']?.toString(),
      dailyQuizId: json['dailyQuizId']?.toString(),
      isCompleted: json['isCompleted'] == true,
      questions: (json['questions'] as List? ?? [])
          .map((e) => QuizQuestion.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class LessonDetailsResponse {
  final LessonVideoDetail video;
  final List<LessonChapter> chapters;
  final List<RelatedVideo> relatedVideos;
  final WatermarkInfo watermark;

  const LessonDetailsResponse({
    required this.video,
    required this.chapters,
    required this.relatedVideos,
    required this.watermark,
  });

  factory LessonDetailsResponse.fromJson(Map<String, dynamic> json) =>
      LessonDetailsResponse(
        video: LessonVideoDetail.fromJson(
            (json['video'] as Map).cast<String, dynamic>()),
        chapters: (json['chapters'] as List? ?? [])
            .map((e) => LessonChapter.fromJson(e.cast<String, dynamic>()))
            .toList(),
        relatedVideos: (json['relatedVideos'] as List? ?? [])
            .map((e) => RelatedVideo.fromJson(e.cast<String, dynamic>()))
            .toList(),
        watermark: WatermarkInfo.fromJson(
            (json['watermark'] as Map).cast<String, dynamic>()),
      );
}
