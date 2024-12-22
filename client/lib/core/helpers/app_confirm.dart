import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

Future<bool> appConfirm(
  BuildContext context, {
  String? title,
  String? content,
  String? textOK,
  String? textCancel,
  bool isDangerous = false,
}) async {
  return await confirm(
    context,
    title: title != null ? Text(title) : null,
    content: content != null ? Text(content) : null,
    textOK: textOK != null
        ? Text(
            isDangerous ? textOK : textOK,
            style: isDangerous
                ? const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE84E4A),
                  )
                : null,
          )
        : Text(
            isDangerous ? t.confirms.confirm.toUpperCase() : t.confirms.confirm,
            style: isDangerous
                ? const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE84E4A),
                  )
                : null,
          ),
    textCancel: textCancel != null ? Text(textCancel) : Text(t.confirms.cancel),
    canPop: true,
  );
}
