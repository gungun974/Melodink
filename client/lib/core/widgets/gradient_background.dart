import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';

class GradientBackground extends ConsumerWidget {
  const GradientBackground({
    super.key,
  });

  AlignmentGeometry gradientEndPoint(double angle) {
    double angleRad = (angle - 90) * (pi / 180);
    return Alignment(cos(angleRad), sin(angleRad));
  }

  AlignmentGeometry gradientStartPoint(double angle) {
    double angleRad = (angle + 90) * (pi / 180);
    return Alignment(cos(angleRad), sin(angleRad));
  }

  Color adjustColorLightness(Color color,
      {double minLightness = 0.4, double maxLightness = 0.8}) {
    final hslColor = HSLColor.fromColor(color);

    final double newLightness =
        hslColor.lightness.clamp(minLightness, maxLightness);

    final newHslColor =
        hslColor.withLightness((newLightness + 0.12).clamp(0, 1));

    return newHslColor.toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPalette = ref.watch(currentTrackPaletteProvider);

    final palette = asyncPalette.valueOrNull;

    final colorA = palette != null
        ? adjustColorLightness(
            Color.fromRGBO(palette[1][0], palette[1][1], palette[1][2], 1))
        : const Color.fromRGBO(58, 91, 111, 1);
    final colorB = palette != null
        ? adjustColorLightness(
            Color.fromRGBO(palette[3][0], palette[3][1], palette[3][2], 1))
        : const Color.fromRGBO(216, 232, 238, 1);
    final colorC = palette != null
        ? adjustColorLightness(
            Color.fromRGBO(palette[0][0], palette[0][1], palette[0][2], 1))
        : const Color.fromRGBO(151, 201, 218, 1);

    return Stack(
      children: [
        Container(
          color: Colors.black87,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutQuad,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: gradientStartPoint(127),
              end: gradientEndPoint(127),
              stops: const [0.0, 0.9],
              colors: [
                Color.fromRGBO(colorA.red, colorA.green, colorA.blue, 0.55),
                Color.fromRGBO(colorA.red, colorA.green, colorA.blue, 0),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutQuad,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: gradientStartPoint(217),
              end: gradientEndPoint(217),
              stops: const [0.0, 0.8],
              colors: [
                Color.fromRGBO(colorB.red, colorB.green, colorB.blue, 0.55),
                Color.fromRGBO(colorB.red, colorB.green, colorB.blue, 0.10),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutQuad,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: gradientStartPoint(336),
              end: gradientEndPoint(336),
              stops: const [0.0, 1],
              colors: [
                Color.fromRGBO(colorC.red, colorC.green, colorC.blue, 0.55),
                Color.fromRGBO(colorC.red, colorC.green, colorC.blue, 0.05),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
