import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/downloaded_video.dart';

class OfflineStorage {
  late Future<Isar> db;

  OfflineStorage() {
    db = _init();
  }

  Future<Isar> _init() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [DownloadedVideoSchema],
        directory: dir.path,
      );
    }
    return Isar.getInstance()!;
  }

  Future<List<DownloadedVideo>> getAllDownloads() async {
    final isar = await db;
    return isar.downloadedVideos.where().sortByDownloadedAtDesc().findAll();
  }

  Future<DownloadedVideo?> getDownload(String videoId) async {
    final isar = await db;
    return isar.downloadedVideos.filter().videoIdEqualTo(videoId).findFirst();
  }

  Future<void> saveDownload(DownloadedVideo video) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.downloadedVideos.put(video);
    });
  }

  Future<void> updatePosition(String videoId, int position) async {
    final isar = await db;
    final video = await getDownload(videoId);
    if (video != null) {
      video.lastPositionSec = position;
      if (video.durationSec > 0 && position >= video.durationSec - 5) {
        video.isCompleted = true;
      }
      await isar.writeTxn(() => isar.downloadedVideos.put(video));
    }
  }

  Future<void> deleteDownload(String videoId) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.downloadedVideos.filter().videoIdEqualTo(videoId).deleteFirst();
    });
  }
}
