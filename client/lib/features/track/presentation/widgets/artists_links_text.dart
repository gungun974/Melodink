import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/core/widgets/hoverable_text.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';

class ArtistsLinksText extends StatelessWidget {
  const ArtistsLinksText({
    super.key,
    required this.artists,
    required this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.textAlign,
    this.alignment,
    this.withTooltip = true,
    this.noInteraction = false,
  });

  final List<Artist> artists;

  final TextStyle style;

  final int? maxLines;

  final TextOverflow overflow;

  final TextAlign? textAlign;
  final Alignment? alignment;

  final bool withTooltip;

  final bool noInteraction;

  @override
  Widget build(BuildContext context) {
    final List<InlineSpan> texts = getArtistsLinksTextSpans(
      context,
      artists,
      style,
      noInteraction,
      maxLines,
      overflow,
    );

    final text = RichText(
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign ?? TextAlign.start,
      text: TextSpan(
        style: style.copyWith(
          fontFamily: "Roboto",
        ),
        children: texts,
      ),
    );

    if (!withTooltip) {
      return Align(
        alignment: alignment ?? Alignment.centerLeft,
        child: text,
      );
    }

    return Align(
      alignment: alignment ?? Alignment.centerLeft,
      child: Tooltip(
        message: artists.map((artist) => artist.name).join(", "),
        waitDuration: const Duration(milliseconds: 800),
        child: text,
      ),
    );
  }
}

@override
List<InlineSpan> getArtistsLinksTextSpans(
  BuildContext context,
  List<Artist> artists,
  TextStyle style,
  bool noInteraction,
  int? maxLines,
  TextOverflow? overflow,
) {
  final List<InlineSpan> texts = [];

  for (final (index, artist) in artists.indexed) {
    texts.add(
      WidgetSpan(
        child: MouseRegion(
          cursor: noInteraction ? MouseCursor.defer : SystemMouseCursors.click,
          child: Listener(
            onPointerDown: noInteraction
                ? null
                : (PointerDownEvent event) {
                    if (event.kind == PointerDeviceKind.touch ||
                        (event.kind == PointerDeviceKind.mouse &&
                            event.buttons != kPrimaryButton)) {
                      return;
                    }

                    while (
                        GoRouter.of(context).location?.startsWith("/queue") ??
                            true) {
                      GoRouter.of(context).pop();
                    }

                    while (
                        GoRouter.of(context).location?.startsWith("/player") ??
                            true) {
                      GoRouter.of(context).pop();
                    }

                    GoRouter.of(context).push("/artist/${artist.id}");
                  },
            child: HoverableText(
              text: artist.name,
              style: style,
              maxLines: maxLines,
              overflow: overflow,
              hoverStyle: noInteraction
                  ? null
                  : style.copyWith(
                      decoration: TextDecoration.underline,
                    ),
            ),
          ),
        ),
      ),
    );

    if (index != artists.length - 1) {
      texts.add(
        const TextSpan(text: ', '),
      );
    }
  }

  return texts;
}
