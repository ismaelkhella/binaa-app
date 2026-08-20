class QbSubject {
  final String id;
  final String name;
  final int unitsCount;

  const QbSubject({
    required this.id,
    required this.name,
    required this.unitsCount,
  });

  factory QbSubject.fromJson(Map<String, dynamic> json) => QbSubject(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        unitsCount: (json['unitsCount'] as num?)?.toInt() ?? 0,
      );
}

class QbUnit {
  final String id;
  final String name;
  final int order;
  final int questionsCount;

  const QbUnit({
    required this.id,
    required this.name,
    required this.order,
    required this.questionsCount,
  });

  factory QbUnit.fromJson(Map<String, dynamic> json) => QbUnit(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        order: (json['order'] as num?)?.toInt() ?? 0,
        questionsCount: (json['questionsCount'] as num?)?.toInt() ?? 0,
      );
}

class QbChoice {
  final String id;
  final String text;

  const QbChoice({
    required this.id,
    required this.text,
  });

  factory QbChoice.fromJson(Map<String, dynamic> json) => QbChoice(
        id: json['id']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
      );
}

class QbQuestion {
  final String id;
  final String text;
  final String? imageUrl;
  final int order;
  final List<QbChoice> choices;

  const QbQuestion({
    required this.id,
    required this.text,
    required this.order,
    required this.choices,
    this.imageUrl,
  });

  factory QbQuestion.fromJson(Map<String, dynamic> json) => QbQuestion(
        id: json['id']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString(),
        order: (json['order'] as num?)?.toInt() ?? 0,
        choices: (json['choices'] as List? ?? [])
            .map((e) => QbChoice.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
}

class QbAnswerResponse {
  final bool isCorrect;
  final String correctChoiceId;

  const QbAnswerResponse({
    required this.isCorrect,
    required this.correctChoiceId,
  });

  factory QbAnswerResponse.fromJson(Map<String, dynamic> json) => QbAnswerResponse(
        isCorrect: json['isCorrect'] == true,
        correctChoiceId: json['correctChoiceId']?.toString() ?? '',
      );
}
