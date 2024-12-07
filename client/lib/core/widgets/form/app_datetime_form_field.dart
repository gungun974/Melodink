import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

enum AppDatetimeFormFieldType {
  date,
  time,
  dateTime,
}

class AppDatetimeFormField extends HookWidget {
  final String labelText;
  final DateFormat formatter;
  final AppDatetimeFormFieldType type;

  final DateTime? value;
  final ValueChanged<DateTime>? onChanged;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final VoidCallback? prefixIconOnPressed;
  final VoidCallback? suffixIconOnPressed;

  const AppDatetimeFormField({
    super.key,
    required this.labelText,
    required this.formatter,
    this.type = AppDatetimeFormFieldType.dateTime,
    this.value,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixIconOnPressed,
    this.suffixIconOnPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController(
      text: value != null ? formatter.format(value!) : "",
    );

    useEffect(() {
      textController.text = value != null ? formatter.format(value!) : "";

      return null;
    }, [value]);

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: GestureDetector(
        onTap: () async {
          DateTime? dateTime = await showOmniDateTimePicker(
            theme: Theme.of(context).copyWith(
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
            context: context,
            initialDate: value,
            is24HourMode: true,
            isShowSeconds: false,
            borderRadius: const BorderRadius.all(Radius.circular(0)),
            constraints: const BoxConstraints(
              maxWidth: 350,
              maxHeight: 650,
            ),
            transitionBuilder: (context, anim1, anim2, child) {
              return FadeTransition(
                opacity: anim1.drive(
                  Tween(
                    begin: 0,
                    end: 1,
                  ),
                ),
                child: child,
              );
            },
            separator: const Divider(),
            type: switch (type) {
              AppDatetimeFormFieldType.date => OmniDateTimePickerType.date,
              AppDatetimeFormFieldType.time => OmniDateTimePickerType.time,
              AppDatetimeFormFieldType.dateTime =>
                OmniDateTimePickerType.dateAndTime,
            },
            transitionDuration: const Duration(milliseconds: 200),
            barrierDismissible: true,
          );

          if (dateTime == null) {
            return;
          }
          onChanged?.call(dateTime);
        },
        child: AbsorbPointer(
          child: AppTextFormField(
            labelText: labelText,
            controller: textController,
          ),
        ),
      ),
    );
  }
}
