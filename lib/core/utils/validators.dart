/// Stateless validation helpers used by form widgets.
class Validators {
  Validators._();

  /// Palestinian phone regex matches the API contract `^05\d{8}$` (10 digits total).
  static final RegExp phoneRegex = RegExp(r'^05\d{8}$');

  static String? phone(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return 'الرجاء إدخال رقم الهاتف';
    if (!phoneRegex.hasMatch(v)) return 'رقم الهاتف يجب أن يكون 10 أرقام ويبدأ بـ 05';
    return null;
  }

  static String? otp(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return 'الرجاء إدخال رمز التحقق';
    if (v.length != 6 || !RegExp(r'^\d{6}$').hasMatch(v)) {
      return 'رمز التحقق 6 أرقام';
    }
    return null;
  }

  static String? parentPhone(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return null; // optional
    if (!phoneRegex.hasMatch(v)) return 'رقم هاتف غير صالح';
    return null;
  }

  static String? requiredField(String? raw, [String label = 'هذا الحقل']) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return '$label مطلوب';
    return null;
  }
}
