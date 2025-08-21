import 'dart:io';
import 'dart:math';

import 'package:color_thief_flutter/color_thief_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:melodink_client/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:melodink_client/features/track/data/repository/download_track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

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

class GradientBackground extends HookConsumerWidget {
  const GradientBackground({super.key});

  AlignmentGeometry gradientEndPoint(double angle) {
    double angleRad = (angle - 90) * (pi / 180);
    return Alignment(cos(angleRad), sin(angleRad));
  }

  AlignmentGeometry gradientStartPoint(double angle) {
    double angleRad = (angle + 90) * (pi / 180);
    return Alignment(cos(angleRad), sin(angleRad));
  }

  Color adjustColorLightness(
    Color color, {
    double minLightness = 0.4,
    double maxLightness = 0.8,
  }) {
    final hslColor = HSLColor.fromColor(color);

    final double newLightness = hslColor.lightness.clamp(
      minLightness,
      maxLightness,
    );

    final newHslColor = hslColor.withLightness(
      (newLightness + 0.12).clamp(0, 1),
    );

    return newHslColor.toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = context.watch<SettingsViewModel>().currentAppTheme();
    final dynamicBackgroundColors = context
        .watch<SettingsViewModel>()
        .shouldDynamicBackgroundColors();

    final audioController = ref.read(audioControllerProvider);
    final downloadTrackRepository = ref.read(downloadTrackRepositoryProvider);

    final palette = useState<List<List<int>>?>(null);

    useOnStreamChange(
      useMemoized(
        () => audioController.currentTrack.stream
            .startWith(audioController.currentTrack.value)
            .distinct((prev, next) => prev?.id == next?.id),
      ),
      onData: (currentTrack) async {
        if (currentTrack == null) {
          return;
        }

        final downloadedTrack = await downloadTrackRepository
            .getDownloadedTrackByTrackId(currentTrack.id);

        final imageUrl =
            downloadedTrack?.getCoverUrl() ??
            currentTrack.getCompressedCoverUrl(
              TrackCompressedCoverQuality.medium,
            );

        Uri? uri = Uri.tryParse(imageUrl);

        ImageProvider imageProvider;

        if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
          imageProvider = FileImage(await ImageCacheManager.getImage(uri));
        } else {
          imageProvider = FileImage(File(imageUrl));
        }

        final image = await getImageFromProvider(imageProvider);

        palette.value = await getPaletteFromImage(image, 5, 5);
      },
    );

    List<Color> appliedTheme = defaultTheme;

    if (dynamicBackgroundColors && palette.value != null) {
      appliedTheme = [
        adjustColorLightness(
          Color.fromRGBO(
            palette.value![1][0],
            palette.value![1][1],
            palette.value![1][2],
            1,
          ),
        ),
        adjustColorLightness(
          Color.fromRGBO(
            palette.value![3][0],
            palette.value![3][1],
            palette.value![3][2],
            1,
          ),
        ),
        adjustColorLightness(
          Color.fromRGBO(
            palette.value![0][0],
            palette.value![0][1],
            palette.value![0][2],
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
        Container(color: Colors.grey[850]),
        Container(color: Colors.black87),
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
