import 'package:intl/intl.dart' as intl;

/// Centralized formatters so the UI shows consistent strings everywhere.
class Formatters {
  Formatters._();

  /// Format a Palestinian phone number as `059X XXX XXXX`.
  static String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return digits;
    if (digits.length < 7) {
      return '${digits.substring(0, 4)} ${digits.substring(4)}';
    }
    return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, digits.length.clamp(7, 11))}';
  }

  /// Format seconds as `HH:MM:SS` or `MM:SS` depending on length.
  static String duration(int seconds) {
    if (seconds <= 0) return '00:00';
    final s = seconds % 60;
    final m = (seconds ~/ 60) % 60;
    final h = seconds ~/ 3600;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h == 0) return '$mm:$ss';
    return '$h:$mm:$ss';
  }

  /// Render ISO 8601 timestamp as Arabic locale date.
  static String date(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return intl.DateFormat('d MMMM y', 'ar').format(dt);
    } catch (_) {
      return iso;
    }
  }

  static String dateTime(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return intl.DateFormat('d MMM y • HH:mm', 'ar').format(dt);
    } catch (_) {
      return iso;
    }
  }

  /// Format price in ILS. Uses the default (en_US) locale to avoid depending on
  /// Arabic number/currency locale data; the symbol + glyph carries the meaning.
  static String currency(num? value) {
    if (value == null) return '—';
    final formatter = intl.NumberFormat.currency(
      symbol: '₪',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  /// Compact number formatter for KPIs (1.2K / 234 / 1.5M).
  static String compact(num value) {
    if (value < 1000) return value.toString();
    if (value < 1000000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
}
