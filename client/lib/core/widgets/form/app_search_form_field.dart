import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class AppSearchFormField extends HookWidget {
  final TextEditingController? controller;

  final TextInputType? keyboardType;

  final bool obscureText;

  final VoidCallback? prefixIconOnPressed;

  final AutovalidateMode? autovalidateMode;

  final String? Function(String?)? validator;

  final ValueChanged<String>? onChanged;

  final bool readOnly;

  final int? maxLines;

  final List<String> autofillHints;

  const AppSearchFormField({
    super.key,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIconOnPressed,
    this.autovalidateMode,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.maxLines = 1,
    this.autofillHints = const <String>[],
  });

  @override
  Widget build(BuildContext context) {
    final internalController = useTextEditingController();

    final currentText = useState((controller ?? internalController).text);

    useEffect(() {
      void listener() {
        currentText.value = (controller ?? internalController).text;
      }

      final c = controller ?? internalController;

      c.addListener(listener);

      return () => c.removeListener(listener);
    }, [controller, internalController]);

    return AppTextFormField(
      labelText: t.general.search,
      prefixIcon: const AdwaitaIcon(
        size: 20,
        AdwaitaIcons.system_search,
      ),
      controller: controller ?? internalController,
      suffixIcon: currentText.value.isNotEmpty
          ? MouseRegion(
              cursor: SystemMouseCursors.click,
              child: const AdwaitaIcon(
                size: 20,
                AdwaitaIcons.window_close,
              ),
            )
          : null,
      suffixIconOnPressed: () {
        final c = controller ?? internalController;

        c.text = "";
        onChanged?.call(c.text);
      },
      keyboardType: keyboardType,
      obscureText: obscureText,
      prefixIconOnPressed: prefixIconOnPressed,
      autovalidateMode: autovalidateMode,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      maxLines: maxLines,
      autofillHints: autofillHints,
    );
  }
}
