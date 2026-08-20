import 'api_enums.dart';

class CommunitySubject {
  final String id;
  final String name;
  final Grade grade;
  final Branch branch;

  const CommunitySubject({
    required this.id,
    required this.name,
    required this.grade,
    required this.branch,
  });

  factory CommunitySubject.fromJson(Map<String, dynamic> json) =>
      CommunitySubject(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        grade: GradeX.fromApi(json['grade']?.toString()),
        branch: BranchX.fromApi(json['branch']?.toString()),
      );
}

enum CommunityMessageType { text, image, file, voice }

class CommunityMessage {
  final String id;
  final String subjectId;
  final CommunityMessageType type;
  final String? content;
  final DateTime createdAt;
  final MessageSender sender;
  final MessageAttachment? attachment;

  const CommunityMessage({
    required this.id,
    required this.subjectId,
    required this.type,
    required this.createdAt,
    required this.sender,
    this.content,
    this.attachment,
  });

  factory CommunityMessage.fromJson(Map<String, dynamic> json) =>
      CommunityMessage(
        id: json['id']?.toString() ?? '',
        subjectId: json['subjectId']?.toString() ?? '',
        type: CommunityMessageType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CommunityMessageType.text,
        ),
        content: json['content']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        sender: MessageSender.fromJson(
            (json['sender'] as Map).cast<String, dynamic>()),
        attachment: json['attachment'] == null
            ? null
            : MessageAttachment.fromJson(
                (json['attachment'] as Map).cast<String, dynamic>()),
      );
}

class MessageSender {
  final String id;
  final UserRole role;
  final String name;
  final String? avatarUrl;

  const MessageSender({
    required this.id,
    required this.role,
    required this.name,
    this.avatarUrl,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) => MessageSender(
        id: json['id']?.toString() ?? '',
        role: UserRoleX.fromApi(json['role']?.toString()),
        name: json['name']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString(),
      );
}

class MessageAttachment {
  final String id;
  final String fileName;
  final String mimeType;
  final int size;
  final String url;

  const MessageAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.url,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      MessageAttachment(
        id: json['id']?.toString() ?? '',
        fileName: json['fileName']?.toString() ?? '',
        mimeType: json['mimeType']?.toString() ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
        url: json['url']?.toString() ?? '',
      );
}
