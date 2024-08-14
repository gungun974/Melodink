import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

String formatTimeago(DateTime date) {
  final difference = DateTime.now().difference(date);

  if (difference.inDays < 30) {
    return timeago.format(
      date,
    );
  }
  return DateFormat.yMMMd().format(date);
}
