import 'package:intl/intl.dart';

class DateFormatter {
  // IST display format: 22-09-2026 21:45:32
  static final DateFormat _displayFormat =
      DateFormat('dd-MM-yyyy HH:mm:ss', 'en_IN');

  // Excel export format (same as display)
  static final DateFormat _excelFormat =
      DateFormat('dd-MM-yyyy HH:mm:ss', 'en_IN');

  // Date-only format for filenames
  static final DateFormat _fileNameFormat = DateFormat('yyyy-MM-dd');

  // Readable date for UI headers
  static final DateFormat _readableDate = DateFormat('dd MMM yyyy');

  /// Format a DateTime to IST display string.
  /// DateTime should already be in IST (UTC+5:30).
  static String toDisplay(DateTime dt) => _displayFormat.format(dt);

  /// Format for Excel export.
  static String toExcel(DateTime dt) => _excelFormat.format(dt);

  /// Format for file names: Student_Records_2026-09-22.xlsx
  static String toFileName(DateTime dt) => _fileNameFormat.format(dt);

  /// Human-readable date.
  static String toReadable(DateTime dt) => _readableDate.format(dt);

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
