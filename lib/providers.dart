import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'core/network/api_client.dart';
import 'core/network/download_manager.dart';
import 'core/network/socket_service.dart';
import 'core/storage/token_storage.dart';
import 'core/storage/offline_storage.dart';
import 'data/models/student_stats.dart';
import 'data/models/video.dart';
import 'data/models/downloaded_video.dart';
import 'data/repositories/admin_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/subject_repository.dart';
import 'data/repositories/subscription_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/video_repository.dart';
import 'core/storage/cache_storage.dart';
import 'data/repositories/teacher_repository.dart';
import 'data/repositories/community_repository.dart';
import 'data/repositories/qb_repository.dart';
import 'data/models/qb.dart';

/// Persistent [TokenStorage] instance for the app's lifetime.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final store = TokenStorage();
  ref.onDispose(store.dispose);
  return store;
});

final cacheStorageProvider = Provider<CacheStorage>((ref) => CacheStorage());

final offlineStorageProvider = Provider<OfflineStorage>((ref) => OfflineStorage());

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final manager = DownloadManager(ref.watch(offlineStorageProvider));
  ref.onDispose(manager.dispose);
  return manager;
});

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService(ref.watch(tokenStorageProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Single [Dio] instance configured with auth + error interceptors.
final dioProvider = Provider<Dio>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  final dio = buildApiClient(tokens);
  ref.onDispose(dio.close);
  return dio;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(dioProvider), ref.watch(cacheStorageProvider)),
);

final subjectRepositoryProvider = Provider<SubjectRepository>(
  (ref) => SubjectRepository(ref.watch(dioProvider), ref.watch(cacheStorageProvider)),
);

final videoRepositoryProvider = Provider<VideoRepository>(
  (ref) => VideoRepository(
    ref.watch(dioProvider),
    ref.watch(cacheStorageProvider),
    ref.watch(offlineStorageProvider),
  ),
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(ref.watch(dioProvider)),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(dioProvider)),
);

final teacherRepositoryProvider = Provider<TeacherRepository>(
  (ref) => TeacherRepository(ref.watch(dioProvider)),
);

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(ref.watch(dioProvider)),
);

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepository(ref.watch(dioProvider)),
);

final qbRepositoryProvider = Provider<QbRepository>(
  (ref) => QbRepository(ref.watch(dioProvider)),
);

final qbSubjectsProvider = FutureProvider<List<QbSubject>>((ref) {
  return ref.watch(qbRepositoryProvider).getSubjects();
});

final qbUnitsProvider = FutureProvider.family<List<QbUnit>, String>((ref, subjectId) {
  return ref.watch(qbRepositoryProvider).getUnits(subjectId);
});

final qbQuestionsProvider = FutureProvider.family<List<QbQuestion>, String>((ref, unitId) {
  return ref.watch(qbRepositoryProvider).getQuestions(unitId);
});

final dashboardDataProvider = FutureProvider<DashboardData>((ref) {
  return ref.read(userRepositoryProvider).getDashboard();
});

final streamTokenProvider =
    FutureProvider.family<StreamTokenResponse, String>((ref, id) {
  return ref.read(videoRepositoryProvider).stream(id);
});

final lastLessonProvider = FutureProvider<ContinueLearning?>((ref) async {
  final data = await ref.read(cacheStorageProvider).getLastLesson();
  if (data == null) return null;
  return ContinueLearning.fromJson(data);
});

final downloadsProvider = StreamProvider<List<DownloadedVideo>>((ref) async* {
  final db = await ref.watch(offlineStorageProvider).db;
  yield* db.downloadedVideos
      .where()
      .sortByDownloadedAtDesc()
      .watch(fireImmediately: true);
});

final downloadStatusProvider = StreamProvider.family<DownloadedVideo?, String>((ref, videoId) async* {
  final db = await ref.watch(offlineStorageProvider).db;
  yield* db.downloadedVideos
      .filter()
      .videoIdEqualTo(videoId)
      .watch(fireImmediately: true)
      .map((list) => list.isEmpty ? null : list.first);
});
