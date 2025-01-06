import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/features/player/domain/providers/audio_provider.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/domain/providers/settings_provider.dart';

const defaultTheme = [
  Color.fromRGBO(58, 91, 111, 1),
  Color.fromRGBO(216, 232, 238, 1),
  Color.fromRGBO(151, 201, 218, 1),
];

const darkTheme = [
  Color.fromRGBO(50, 40, 50, 1),
  Color.fromRGBO(20, 20, 30, 1),
  Color.fromRGBO(60, 80, 80, 1),
];

const purpleTheme = [
  Color.fromRGBO(205, 207, 224, 1),
  Color.fromRGBO(111, 86, 179, 1),
  Color.fromRGBO(159, 108, 177, 1),
];

const greyTheme = [
  Color.fromRGBO(235, 235, 235, 1),
  Color.fromRGBO(195, 195, 195, 1),
  Color.fromRGBO(133, 133, 133, 1),
];

const cyanTheme = [
  Color.fromRGBO(128, 216, 183, 1),
  Color.fromRGBO(79, 187, 151, 1),
  Color.fromRGBO(48, 156, 217, 1),
];

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
    final currentTheme = ref.watch(currentAppThemeProvider);
    final dynamicBackgroundColors =
        ref.watch(shouldDynamicBackgroundColorsProvider);

    final asyncPalette = ref.watch(currentTrackPaletteProvider);

    final palette = asyncPalette.valueOrNull;

    List<Color> appliedTheme = defaultTheme;

    if (dynamicBackgroundColors && palette != null) {
      appliedTheme = [
        adjustColorLightness(
          Color.fromRGBO(
            palette[1][0],
            palette[1][1],
            palette[1][2],
            1,
          ),
        ),
        adjustColorLightness(
          Color.fromRGBO(
            palette[3][0],
            palette[3][1],
            palette[3][2],
            1,
          ),
        ),
        adjustColorLightness(
          Color.fromRGBO(
            palette[0][0],
            palette[0][1],
            palette[0][2],
            1,
          ),
        ),
      ];
    } else if (currentTheme == AppSettingTheme.dark) {
      appliedTheme = darkTheme;
    } else if (currentTheme == AppSettingTheme.purple) {
      appliedTheme = purpleTheme;
    } else if (currentTheme == AppSettingTheme.cyan) {
      appliedTheme = cyanTheme;
    } else if (currentTheme == AppSettingTheme.grey) {
      appliedTheme = greyTheme;
    }

    return Stack(
      children: [
        Container(
          color: Colors.grey[850],
        ),
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
                Color.fromRGBO(
                  appliedTheme[0].red,
                  appliedTheme[0].green,
                  appliedTheme[0].blue,
                  0.55,
                ),
                Color.fromRGBO(
                  appliedTheme[0].red,
                  appliedTheme[0].green,
                  appliedTheme[0].blue,
                  0,
                ),
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
                Color.fromRGBO(
                  appliedTheme[1].red,
                  appliedTheme[1].green,
                  appliedTheme[1].blue,
                  0.55,
                ),
                Color.fromRGBO(
                  appliedTheme[1].red,
                  appliedTheme[1].green,
                  appliedTheme[1].blue,
                  0.10,
                ),
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
                Color.fromRGBO(
                  appliedTheme[2].red,
                  appliedTheme[2].green,
                  appliedTheme[2].blue,
                  0.55,
                ),
                Color.fromRGBO(
                  appliedTheme[2].red,
                  appliedTheme[2].green,
                  appliedTheme[2].blue,
                  0.05,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
