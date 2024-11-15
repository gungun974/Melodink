import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago_flutter/timeago_flutter.dart';

String formatTimeago(DateTime date) {
  final difference = DateTime.now().difference(date);

  if (difference.inDays < 30) {
    return timeago.format(
      date,
    );
  }
  return DateFormat.yMMMd().format(date);
}

class FormatTimeago extends TimerRefreshWidget {
  const FormatTimeago({
    super.key,
    required this.builder,
    required this.date,
    Duration super.refreshRate = const Duration(seconds: 30),
  });

  final TimeagoBuilder builder;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final formatted = formatTimeago(date);
    return builder(context, formatted);
  }
}
