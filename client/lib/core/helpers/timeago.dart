import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago_flutter/timeago_flutter.dart';

String formatTimeago(
  DateTime date, {
  String? locale,
}) {
  final difference = DateTime.now().difference(date);

  if (difference.inDays < 30) {
    return timeago.format(date, locale: locale);
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
    return StreamBuilder(
        stream: LocaleSettings.getLocaleStream(),
        builder: (context, snapshot) {
          final formatted = formatTimeago(
            date,
            locale: Localizations.localeOf(context).toString(),
          );
          return builder(context, formatted);
        });
  }
}
