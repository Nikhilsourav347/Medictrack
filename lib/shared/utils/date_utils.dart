import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _displayDateTimeFormat =
      DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  /// Returns current datetime as ISO string for DB storage
  static String nowString() {
    return _dateTimeFormat.format(DateTime.now());
  }

  /// Returns today's date as ISO string for DB storage
  static String todayString() {
    return _dateFormat.format(DateTime.now());
  }

  /// Parses an ISO date string from DB
  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Human-friendly display: "23 Jun 2026"
  static String formatDisplay(String? dateStr) {
    final dt = parseDate(dateStr);
    if (dt == null) return '—';
    return _displayFormat.format(dt);
  }

  /// Human-friendly display with time: "23 Jun 2026, 02:30 PM"
  static String formatDisplayWithTime(String? dateStr) {
    final dt = parseDate(dateStr);
    if (dt == null) return '—';
    return _displayDateTimeFormat.format(dt);
  }

  /// Time only: "02:30 PM"
  static String formatTime(String? dateStr) {
    final dt = parseDate(dateStr);
    if (dt == null) return '—';
    return _timeFormat.format(dt);
  }

  /// Returns date string N days ago
  static String daysAgoString(int days) {
    final dt = DateTime.now().subtract(Duration(days: days));
    return _dateFormat.format(dt);
  }

  /// True if dateStr is today
  static bool isToday(String? dateStr) {
    final dt = parseDate(dateStr);
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// Returns "Today", "Yesterday" or formatted date
  static String relativeDate(String? dateStr) {
    final dt = parseDate(dateStr);
    if (dt == null) return '—';
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return _displayFormat.format(dt);
  }

  /// Formats a DB date string to display datetime
  static String toDisplayDateTime(String recordedAt) {
    return formatDisplayWithTime(recordedAt);
  }
}
