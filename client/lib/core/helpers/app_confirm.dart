import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';

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
            textOK,
            style: isDangerous
                ? const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE84E4A),
                  )
                : null,
          )
        : null,
    textCancel: textCancel != null ? Text(textCancel) : null,
    canPop: true,
  );
}
