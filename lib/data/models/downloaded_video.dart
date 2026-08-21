import 'package:isar/isar.dart';

part 'downloaded_video.g.dart';

@collection
class DownloadedVideo {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String videoId;

  late String title;
  late String subHeader;
  late String? unitName;
  late String? thumbnail;
  
  late String localPath;
  late DateTime downloadedAt;
  late int sizeInBytes;
  
  @Index()
  int lastPositionSec = 0;
  
  int durationSec = 0;
  
  @Index()
  bool isCompleted = false;

  String? checksum;
  
  DateTime? expiresAt;

  // Status: 0=pending, 1=downloading, 2=completed, 3=failed
  int status = 0;
}
