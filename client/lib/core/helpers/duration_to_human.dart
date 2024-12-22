import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

String durationToHuman(
  Duration duration,
  BuildContext context,
) {
  final locale = DurationLocale.fromLanguageCode(
    Localizations.localeOf(context).toString(),
  );

  return prettyDuration(
    duration,
    delimiter: ", ",
    conjunction: " ${t.general.and} ",
    abbreviated: false,
    locale: locale ?? const EnglishDurationLocale(),
  );
}
