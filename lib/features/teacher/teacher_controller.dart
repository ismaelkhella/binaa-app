import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/teacher.dart';
import '../../providers.dart';

final teacherDashboardProvider = FutureProvider<TeacherDashboard>((ref) {
  return ref.read(teacherRepositoryProvider).getDashboard();
});
