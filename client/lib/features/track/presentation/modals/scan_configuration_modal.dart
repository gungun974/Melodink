import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class ScanConfiguration extends Equatable {
  final bool advancedScan;
  final bool onlyReplaceEmptyFields;

  const ScanConfiguration({
    required this.advancedScan,
    required this.onlyReplaceEmptyFields,
  });

  @override
  List<Object> get props => [
        advancedScan,
        onlyReplaceEmptyFields,
      ];
}

class ScanConfigurationModal extends HookWidget {
  final bool hideAdvancedScanQuestion;

  const ScanConfigurationModal({
    super.key,
    required this.hideAdvancedScanQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final advancedScan = useState(false);
    final onlyReplaceEmptyFields = useState(true);

    return MaxContainer(
      maxWidth: 440,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 64,
      ),
      child: Stack(
        children: [
          Center(
            child: IntrinsicHeight(
              child: AppModal(
                preventUserClose: true,
                title: Text(t.general.scan),
                body: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!hideAdvancedScanQuestion)
                        CheckboxListTile(
                          title: Text(
                            t.general.advancedScan,
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                              letterSpacing: 16 * 0.04,
                            ),
                          ),
                          value: advancedScan.value,
                          onChanged: (value) {
                            advancedScan.value = value ?? false;
                          },
                          activeColor: const Color.fromRGBO(196, 126, 208, 1),
                        ),
                      CheckboxListTile(
                        title: Text(
                          t.settings.replaceOnlyEmptyFields,
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            letterSpacing: 16 * 0.04,
                          ),
                        ),
                        value: onlyReplaceEmptyFields.value,
                        onChanged: (value) {
                          onlyReplaceEmptyFields.value = value ?? false;
                        },
                        activeColor: const Color.fromRGBO(196, 126, 208, 1),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 40,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(t.general.cancel),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: AppButton(
                              text: t.general.scan,
                              type: AppButtonType.primary,
                              onPressed: () {
                                Navigator.of(context).pop(ScanConfiguration(
                                  advancedScan: advancedScan.value,
                                  onlyReplaceEmptyFields:
                                      onlyReplaceEmptyFields.value,
                                ));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<ScanConfiguration?> showModal(
    BuildContext context, {
    bool hideAdvancedScanQuestion = false,
  }) async {
    return await showDialog<ScanConfiguration>(
      context: context,
      builder: (BuildContext context) => PopScope(
        canPop: true,
        child: ScanConfigurationModal(
          hideAdvancedScanQuestion: hideAdvancedScanQuestion,
        ),
      ),
    );
  }
}
