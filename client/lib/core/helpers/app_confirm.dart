import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

Future<bool> appConfirm(
  BuildContext context, {
  String? title,
  String? content,
  String? textOK,
  String? textCancel,
  bool isDangerous = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => PopScope(
      canPop: true,
      child: _AppConfirmModal(
        title: title,
        content: content,
        textOK: textOK,
        textCancel: textCancel,
        isDangerous: isDangerous,
      ),
    ),
  );

  return result ?? false;
}

class _AppConfirmModal extends StatelessWidget {
  final String? title;
  final String? content;
  final String? textOK;
  final String? textCancel;
  final bool isDangerous;

  const _AppConfirmModal({
    required this.title,
    required this.content,
    required this.textOK,
    required this.textCancel,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    final textOK = this.textOK != null
        ? Text(
            isDangerous ? this.textOK!.toUpperCase() : this.textOK!,
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
          );

    final textCancel = this.textCancel != null
        ? Text(this.textCancel!)
        : Text(t.confirms.cancel);

    return MaxContainer(
      maxWidth: 440,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 64,
      ),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: IntrinsicWidth(
            child: IntrinsicHeight(
              child: Stack(
                children: [
                  GradientBackground(),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 24.0,
                      bottom: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 8.0, right: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    title!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18,
                                      letterSpacing: 18 * 0.04,
                                    ),
                                  ),
                                ),
                              if (content != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, bottom: 16.0),
                                  child: Text(
                                    content!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      letterSpacing: 14 * 0.04,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: textCancel,
                            ),
                            SizedBox(width: 4),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: textOK,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
