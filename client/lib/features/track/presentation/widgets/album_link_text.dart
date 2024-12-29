import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/core/widgets/hoverable_text.dart';

class AlbumLinkText extends StatelessWidget {
  const AlbumLinkText({
    super.key,
    required this.text,
    required this.albumId,
    required this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.textAlign,
    this.alignment,
    this.withTooltip = true,
    this.noInteraction = false,
    this.openWithScrollOnSpecificTrackId,
  });

  final String text;
  final String albumId;

  final TextStyle style;

  final int? maxLines;

  final TextOverflow overflow;

  final TextAlign? textAlign;
  final Alignment? alignment;

  final bool withTooltip;

  final bool noInteraction;

  final int? openWithScrollOnSpecificTrackId;

  @override
  Widget build(BuildContext context) {
    final textWidget = MouseRegion(
      cursor: noInteraction ? MouseCursor.defer : SystemMouseCursors.click,
      child: SizedBox(
        child: Listener(
          onPointerDown: noInteraction
              ? null
              : (PointerDownEvent event) {
                  if (event.kind == PointerDeviceKind.touch ||
                      (event.kind == PointerDeviceKind.mouse &&
                          event.buttons != kPrimaryButton)) {
                    return;
                  }

                  while (GoRouter.of(context).location?.startsWith("/queue") ??
                      true) {
                    GoRouter.of(context).pop();
                  }

                  while (GoRouter.of(context).location?.startsWith("/player") ??
                      true) {
                    GoRouter.of(context).pop();
                  }

                  GoRouter.of(context).push("/album/$albumId", extra: {
                    "openWithScrollOnSpecificTrackId":
                        openWithScrollOnSpecificTrackId,
                  });
                },
          child: HoverableText(
            text: text,
            style: style,
            hoverStyle: noInteraction
                ? null
                : style.copyWith(
                    decoration: TextDecoration.underline,
                  ),
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          ),
        ),
      ),
    );

    if (!withTooltip) {
      return Align(
        alignment: alignment ?? Alignment.centerLeft,
        child: textWidget,
      );
    }

    return Align(
      alignment: alignment ?? Alignment.centerLeft,
      child: Tooltip(
        message: text,
        waitDuration: const Duration(milliseconds: 800),
        child: textWidget,
      ),
    );
  }
}
