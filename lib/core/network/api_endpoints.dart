/// Single source of truth for API paths. The base URL comes from [AppConfig].
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ─────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String setupProfile = '/auth/setup-profile';
  static const String adminLogin = '/auth/admin/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // ── User / Dashboard ────────────────────────────────────
  static const String me = '/me';
  static const String updateParentPhone = '/me/parent-phone';
  static const String dashboard = '/dashboard';
  static const String performance = '/performance';
  static const String goals = '/goals';
  static String goal(String id) => '/goals/$id';

  // ── Subjects ─────────────────────────────────────────────
  static const String subjects = '/subjects';
  static const String mySubjects = '/subjects/my';
  static String subjectVideos(String id) => '/subjects/$id/videos';

  // ── Videos ───────────────────────────────────────────────
  static String video(String id) => '/videos/$id';
  static String videoStream(String id) => '/videos/$id/stream';
  static String videoMarkViewed(String id) => '/videos/$id/mark-viewed';
  static String videoPosition(String id) => '/videos/$id/position';
  static String videoDownloadToken(String id) => '/videos/$id/download-token';

  // ── Subscriptions ────────────────────────────────────────
  static const String subscriptionPlans = '/subscriptions/plans';
  static const String mySubscription = '/subscriptions/me';

  // ── Teacher ──────────────────────────────────────────────
  static const String teacherDashboard = '/teacher/dashboard';

  // ── Community ────────────────────────────────────────────
  static const String communitySubjects = '/community/subjects';
  static String communityMessages(String subjectId) => '/community/$subjectId/messages';
  static String communityAttachment(String id) => '/community/attachments/$id';
  static String adminCommunityMessages(String subjectId) => '/admin/community/$subjectId/messages';
  static String adminCommunityMessage(String id) => '/admin/community/messages/$id';
  static String adminCommunityAttachment(String id) => '/admin/community/attachments/$id';
  static String adminTeacherCredentials(String id) => '/admin/teachers/$id/credentials';

  // ── Admin ────────────────────────────────────────────────
  static const String adminDashboard = '/admin/dashboard';
  static const String adminStudents = '/admin/students';
  static String adminStudent(String id) => '/admin/students/$id';
  static String adminStudentFreeze(String id) =>
      '/admin/students/$id/subscription/freeze';
  static String adminStudentGrant(String id) =>
      '/admin/students/$id/subscription/grant';
  static const String adminVideos = '/admin/videos';
  static String adminVideo(String id) => '/admin/videos/$id';
  static const String adminSubjects = '/admin/subjects';
  static const String adminPlans = '/admin/plans';
  static String adminPlan(String id) => '/admin/plans/$id';
  static const String adminTeachers = '/admin/teachers';
  static const String adminTeachersDashboard = '/admin/teachers/dashboard';
  static const String adminUpload = '/admin/upload';
  static const String muxCreateUpload = '/mux/create-upload';

  // ── Cart ─────────────────────────────────────────────────
  static const String cart = '/cart';
  static const String addToCart = '/cart/add';
  static String removeFromCart(String id) => '/cart/remove/$id';
  static const String checkout = '/cart/checkout';

  // ── Question Bank (QB) ──────────────────────────────────
  static const String qbSubjects = '/qb/subjects';
  static String qbUnits(String subjectId) => '/qb/subjects/$subjectId/units';
  static String qbQuestions(String unitId) => '/qb/units/$unitId/questions';
  static String qbAnswer(String questionId) => '/qb/questions/$questionId/answer';
}
