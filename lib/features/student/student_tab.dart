import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the bottom-nav tab for the student app. Owned by the scaffold;
/// any descendant widget (e.g. dashboard cards) can request a tab change via
/// [selectedStudentTabProvider.notifier].
final selectedStudentTabProvider = StateProvider<int>((_) => 0);

enum StudentTab {
  dashboard(0),
  subjects(1),
  community(2),
  goals(3),
  profile(4);

  final int idx;
  const StudentTab(this.idx);
}
