import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AppTextFormField extends StatelessWidget {
  final String labelText;

  final TextEditingController? controller;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final TextInputType? keyboardType;

  final bool obscureText;

  final VoidCallback? prefixIconOnPressed;
  final VoidCallback? suffixIconOnPressed;

  final AutovalidateMode? autovalidateMode;

  final String? Function(String?)? validator;

  final ValueChanged<String>? onChanged;

  final bool readOnly;

  const AppTextFormField({
    super.key,
    required this.labelText,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIconOnPressed,
    this.suffixIconOnPressed,
    this.autovalidateMode,
    this.validator,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      autovalidateMode: autovalidateMode,
      validator: validator,
      initialValue: controller?.text ?? "",
      builder: (FormFieldState field) {
        return Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(39, 44, 46, 0.55),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Stack(
            children: [
              SizedBox(
                height: 40,
                child: Center(
                  child: TextField(
                    controller: controller,
                    onChanged: (String value) {
                      field.didChange(value);
                      onChanged?.call(value);
                    },
                    readOnly: readOnly,
                    obscureText: obscureText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 24 * 0.03,
                      fontWeight: FontWeight.w400,
                      height: Platform.isLinux ? 1.4 : 1,
                    ),
                    maxLines: 1,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      prefixIcon: prefixIcon != null ? buildPrefixIcon() : null,
                      prefixIconConstraints: const BoxConstraints(),
                      suffixIcon: suffixIcon != null ? buildSuffixIcon() : null,
                      suffixIconConstraints: const BoxConstraints(),
                      isDense: true,
                      filled: false,
                      labelText: labelText,
                      labelStyle: TextStyle(color: Colors.grey[350]),
                      floatingLabelStyle: TextStyle(
                        color: Colors.grey[350],
                        fontSize: 12,
                        letterSpacing: 12 * 0.03,
                        fontWeight: FontWeight.w400,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: Platform.isLinux ? 16 : 14,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: Platform.isLinux ? 16 : 14,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.transparent,
                          width: Platform.isLinux ? 16 : 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (field.hasError)
                SizedBox(
                  height: 40 + 5,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text(
                        field.errorText!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          letterSpacing: 11 * 0.03,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  Widget buildPrefixIcon() {
    final iconWidget = Container(
      height: 40,
      padding: const EdgeInsets.only(left: 16.0, right: 12.0),
      color: Colors.transparent,
      child: prefixIcon,
    );

    if (prefixIconOnPressed == null) {
      return iconWidget;
    }

    return GestureDetector(
      onTap: prefixIconOnPressed,
      child: iconWidget,
    );
  }

  Widget buildSuffixIcon() {
    final iconWidget = Container(
      height: 40,
      padding: const EdgeInsets.only(left: 12.0, right: 16.0),
      color: Colors.transparent,
      child: suffixIcon,
    );

    if (suffixIconOnPressed == null) {
      return iconWidget;
    }

    return GestureDetector(
      onTap: suffixIconOnPressed,
      child: iconWidget,
    );
  }
}

class AppReadTextField extends HookWidget {
  final String labelText;
  final String value;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final VoidCallback? prefixIconOnPressed;
  final VoidCallback? suffixIconOnPressed;

  const AppReadTextField({
    super.key,
    required this.labelText,
    required this.value,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixIconOnPressed,
    this.suffixIconOnPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController(text: value);

    useEffect(() {
      textController.text = value;

      return null;
    }, [value]);

    return AppTextFormField(
      controller: textController,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      prefixIconOnPressed: prefixIconOnPressed,
      suffixIconOnPressed: suffixIconOnPressed,
      readOnly: true,
    );
  }
}
