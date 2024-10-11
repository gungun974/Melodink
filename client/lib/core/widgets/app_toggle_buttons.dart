import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppToggleButtonsOption {
  final String text;
  final String icon;

  AppToggleButtonsOption({
    required this.text,
    required this.icon,
  });
}

class AppToggleButtons extends StatelessWidget {
  final List<AppToggleButtonsOption> options;

  final List<bool> isSelected;

  final void Function(int index)? onPressed;

  const AppToggleButtons({
    super.key,
    required this.options,
    required this.isSelected,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      constraints: const BoxConstraints(
        minHeight: 36.0,
      ),
      isSelected: isSelected,
      borderRadius: BorderRadius.circular(10),
      borderWidth: 2,
      borderColor: const Color.fromRGBO(196, 126, 208, 1),
      selectedBorderColor: const Color.fromRGBO(196, 126, 208, 1),
      selectedColor: Colors.white,
      fillColor: const Color.fromRGBO(196, 126, 208, 1),
      onPressed: onPressed,
      children: options
          .map(
            (option) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (context) {
                      final iconTheme = IconTheme.of(context);

                      final selectedColor = iconTheme.color;

                      return option.icon.endsWith(".vec")
                          ? AdwaitaIcon(
                              option.icon,
                              size: 20,
                            )
                          : SvgPicture.asset(
                              option.icon,
                              width: 20,
                              height: 20,
                              colorFilter: selectedColor != null
                                  ? ColorFilter.mode(
                                      selectedColor, BlendMode.srcIn)
                                  : null,
                            );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    option.text,
                    style: const TextStyle(
                      fontSize: 14,
                      letterSpacing: 14 * 0.03,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
