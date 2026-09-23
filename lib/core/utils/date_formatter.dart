import 'package:intl/intl.dart';

class DateFormatter {
  // IST display format: 22-09-2026 21:45:32 (no locale required for pure digits)
  static final DateFormat _displayFormat = DateFormat('dd-MM-yyyy HH:mm:ss');

  // Excel export format (same as display)
  static final DateFormat _excelFormat = DateFormat('dd-MM-yyyy HH:mm:ss');

  // Date-only format for filenames
  static final DateFormat _fileNameFormat = DateFormat('yyyy-MM-dd');

  // Readable date for UI headers
  static final DateFormat _readableDate = DateFormat('dd MMM yyyy');

  /// Format a DateTime to IST display string.
  /// DateTime should already be in IST (UTC+5:30).
  static String toDisplay(DateTime dt) {
    try {
      return _displayFormat.format(dt);
    } catch (_) {
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      return '$d-$m-$y $h:$min:$s';
    }
  }

  /// Format for Excel export.
  static String toExcel(DateTime dt) => toDisplay(dt);

  /// Format for file names: Student_Records_2026-09-22.xlsx
  static String toFileName(DateTime dt) {
    try {
      return _fileNameFormat.format(dt);
    } catch (_) {
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      return '$y-$m-$d';
    }
  }

  /// Human-readable date.
  static String toReadable(DateTime dt) {
    try {
      return _readableDate.format(dt);
    } catch (_) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final d = dt.day.toString().padLeft(2, '0');
      final m = (dt.month >= 1 && dt.month <= 12) ? months[dt.month - 1] : '';
      final y = dt.year.toString();
      return '$d $m $y';
    }
  }

  /// Get current IST DateTime.
  static DateTime nowIST() {
    final utc = DateTime.now().toUtc();
    return utc.add(const Duration(hours: 5, minutes: 30));
  }

  /// Check if a DateTime (IST) is today.
  static bool isToday(DateTime dt) {
    final now = nowIST();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// Parse from UTC DateTime → IST DateTime.
  static DateTime fromTimestamp(DateTime utc) {
    return utc.toUtc().add(const Duration(hours: 5, minutes: 30));
  }
}
