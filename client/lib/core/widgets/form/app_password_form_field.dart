import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';

class AppPasswordFormField extends HookWidget {
  final String labelText;

  final TextEditingController? controller;

  final AutovalidateMode? autovalidateMode;

  final String? Function(String?)? validator;

  const AppPasswordFormField({
    super.key,
    required this.labelText,
    this.controller,
    this.autovalidateMode,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isVisible = useState(false);

    return AppTextFormField(
      controller: controller,
      autovalidateMode: autovalidateMode,
      validator: validator,
      obscureText: !isVisible.value,
      keyboardType: TextInputType.text,
      labelText: labelText,
      iconOnPressed: () {
        isVisible.value = !isVisible.value;
      },
      icon: AdwaitaIcon(
        size: 20,
        !isVisible.value ? AdwaitaIcons.view_reveal : AdwaitaIcons.view_conceal,
      ),
    );
  }
}