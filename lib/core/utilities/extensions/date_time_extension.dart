import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  int get dateKey => year * 10000 + month * 100 + day;

  String format(String pattern) {
    return DateFormat(pattern, 'id_ID').format(this);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool isToday() => isSameDay(DateTime.now());

  bool isYesterday() =>
      isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  bool isTomorrow() => isSameDay(DateTime.now().add(const Duration(days: 1)));

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  bool isSameYear(DateTime other) => year == other.year;

  String timeAgo([String? pattern]) {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return format(pattern ?? 'dd MMM yyyy');
  }

  DateTime? tryParseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
