import 'package:flutter/material.dart';

class AppTextFormField extends StatelessWidget {
  final String labelText;

  final TextEditingController? controller;

  final Widget? icon;

  final TextInputType? keyboardType;

  final bool obscureText;

  final VoidCallback? iconOnPressed;

  final AutovalidateMode? autovalidateMode;

  final String? Function(String?)? validator;

  final ValueChanged<String>? onChanged;

  const AppTextFormField({
    super.key,
    required this.labelText,
    this.controller,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.iconOnPressed,
    this.autovalidateMode,
    this.validator,
    this.onChanged,
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
            color: const Color(0xFF465156),
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
                    obscureText: obscureText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 24 * 0.03,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      suffixIcon: icon != null ? buildIcon() : null,
                      suffixIconConstraints: const BoxConstraints(),
                      isDense: true,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      labelText: labelText,
                      labelStyle: TextStyle(color: Colors.grey[350]),
                      floatingLabelStyle: TextStyle(
                        color: Colors.grey[350],
                        fontSize: 12,
                        letterSpacing: 12 * 0.03,
                        fontWeight: FontWeight.w400,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
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

  Widget buildIcon() {
    final iconWidget = Container(
      height: 40,
      padding: const EdgeInsets.only(left: 12.0, right: 16.0),
      color: Colors.transparent,
      child: icon,
    );

    if (iconOnPressed == null) {
      return iconWidget;
    }

    return GestureDetector(
      onTap: iconOnPressed,
      child: iconWidget,
    );
  }
}
