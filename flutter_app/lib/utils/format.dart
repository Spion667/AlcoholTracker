import 'package:intl/intl.dart';

final _hm = DateFormat('HH:mm');
final _dmy = DateFormat('dd.MM.yyyy');

/// `20:15` (lokale Zeit).
String formatClock(DateTime t) => _hm.format(t.toLocal());

/// `11.10.2026` (lokale Zeit).
String formatDate(DateTime t) => _dmy.format(t.toLocal());

/// `gerade eben`, `vor 5 min`, `vor 2 h`.
String timeAgo(DateTime t, {DateTime? now}) {
  final diffSec = (now ?? DateTime.now()).difference(t).inSeconds;
  if (diffSec < 60) return 'gerade eben';
  final diffMin = diffSec ~/ 60;
  if (diffMin < 60) return 'vor $diffMin min';
  return 'vor ${diffMin ~/ 60} h';
}

/// `0,12` statt `0.12`.
String commaDecimal(num v, int digits) =>
    v.toStringAsFixed(digits).replaceFirst('.', ',');
