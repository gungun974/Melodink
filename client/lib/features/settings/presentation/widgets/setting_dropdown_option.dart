import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class SettingDropdownOption<T> extends StatelessWidget {
  const SettingDropdownOption({
    super.key,
    required this.text,
    required this.value,
    required this.onChanged,
    required this.items,
  });

  final String text;

  final T? value;

  final ValueChanged<T?>? onChanged;

  final List<DropdownMenuItem<T>>? items;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontWeight: FontWeight.w300,
      fontSize: 12,
      letterSpacing: 14 * 0.04,
    );

    double? estimateSize;

    if (items != null) {
      for (var i = 0; i < items!.length; i++) {
        final item = items![i].child;

        if (item is! Text) {
          estimateSize = null;
          break;
        }

        final span = TextSpan(
          text: item.data,
          style: textStyle,
        );

        final textPainter = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        if ((estimateSize ?? 0) < textPainter.width) {
          estimateSize = textPainter.width;
        }
      }
    }

    return Row(
      children: [
        Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 15,
            letterSpacing: 15 * 0.04,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<T>(
              isExpanded: true,
              isDense: true,
              items: items,
              value: value,
              onChanged: onChanged,
              buttonStyleData: ButtonStyleData(
                padding: const EdgeInsets.only(
                  left: 16 / 2,
                ),
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: const Color.fromRGBO(39, 44, 46, 0.55),
                ),
              ),
              style: textStyle,
              menuItemStyleData: const MenuItemStyleData(
                height: 32,
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                padding: EdgeInsets.zero,
                width: estimateSize != null ? estimateSize + 24 : null,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
