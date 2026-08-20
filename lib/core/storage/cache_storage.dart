import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheStorage {
  static const String _dashboardKey = 'cached_dashboard';
  static const String _subjectsKey = 'cached_subjects';
  static const String _mySubjectsKey = 'cached_my_subjects';
  static const String _subjectVideosPrefix = 'cached_videos_';
  static const String _lessonDetailsPrefix = 'cached_lesson_';
  static const String _meKey = 'cached_me';
  static const String _lastLessonKey = 'last_lesson';

  Future<void> saveLessonDetails(String videoId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_lessonDetailsPrefix$videoId', jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getLessonDetails(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_lessonDetailsPrefix$videoId');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveLastLesson(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLessonKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getLastLesson() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastLessonKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveSubjectVideos(String subjectId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_subjectVideosPrefix$subjectId', jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getSubjectVideos(String subjectId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_subjectVideosPrefix$subjectId');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveDashboard(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dashboardKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dashboardKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveSubjects(List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subjectsKey, jsonEncode(data));
  }

  Future<List<dynamic>?> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_subjectsKey);
    if (raw == null) return null;
    return jsonDecode(raw) as List<dynamic>;
  }

  Future<void> saveMySubjects(List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mySubjectsKey, jsonEncode(data));
  }

  Future<List<dynamic>?> getMySubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mySubjectsKey);
    if (raw == null) return null;
    return jsonDecode(raw) as List<dynamic>;
  }

  Future<void> saveMe(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_meKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getMe() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_meKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dashboardKey);
    await prefs.remove(_subjectsKey);
    await prefs.remove(_mySubjectsKey);
    await prefs.remove(_meKey);
  }
}
