import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/debounce.dart';
import 'package:melodink_client/core/network/network_info.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/features/settings/domain/entities/settings.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:melodink_client/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/events/track_events.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class TrackScore extends HookWidget {
  final Track track;

  final bool largeControlButton;

  const TrackScore({
    super.key,
    required this.track,
    this.largeControlButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final scoringSystem = context
        .watch<SettingsViewModel>()
        .currentScoringSystem();

    final eventBus = context.read<EventBus>();
    final trackRepository = context.read<TrackRepository>();

    final refresh = useState(UniqueKey());

    final updateScoreDebouncer = useMemoized(
      () => Debouncer(milliseconds: 100),
    );

    final isUserTrigger = useState(false);
    final internalScore = useState(track.score);

    useEffect(() {
      if (isUserTrigger.value) {
        return;
      }
      internalScore.value = track.score;
      return null;
    }, [track.score, isUserTrigger]);

    if (scoringSystem == AppSettingScoringSystem.none) {
      return SizedBox.shrink();
    }

    if (scoringSystem == AppSettingScoringSystem.like) {
      final likeActive = internalScore.value >= 0.8;

      return SizedBox(
        width: largeControlButton ? null : getSize(scoringSystem),
        child: GestureDetector(
          onTap: () {},
          onDoubleTap: () {},
          child: Container(
            height: 50,
            color: Colors.transparent,
            child: Listener(
              onPointerDown: (_) async {
                if (!NetworkInfo().isServerRecheable()) {
                  AppNotificationManager.of(context).notify(
                    context,
                    title: t.notifications.offline.title,
                    message: t.notifications.offline.message,
                    type: AppNotificationType.danger,
                  );
                  return;
                }

                final newScore = likeActive ? 0.0 : 1.0;

                internalScore.value = newScore;

                final newTrack = await trackRepository.setTrackScore(
                  track.id,
                  newScore,
                );

                eventBus.fire(EditTrackEvent(updatedTrack: newTrack));
              },
              child: AppIconButton(
                padding: EdgeInsets.symmetric(
                  horizontal: largeControlButton ? 12 : 16,
                ),
                icon: likeActive
                    ? const AdwaitaIcon(AdwaitaIcons.heart_filled)
                    : const AdwaitaIcon(AdwaitaIcons.heart_outline_thick),
                color: likeActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                iconSize: largeControlButton ? 24.0 : 20.0,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      onDoubleTap: () {},
      child: SizedBox(
        width: largeControlButton ? null : getSize(scoringSystem),
        height: 50,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Center(
            child: RatingBar.builder(
              key: refresh.value,
              initialRating: internalScore.value * 5,
              minRating: 0,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemHeight: 50,
              itemWidth: largeControlButton ? 24.0 : 20.0,
              itemBuilder: (context, _) => Container(
                height: 50,
                width: largeControlButton ? 24.0 : 20.0,
                color: Colors.transparent,
                child: Icon(
                  Icons.star,
                  color: Theme.of(context).colorScheme.primary,
                  size: largeControlButton ? 24.0 : 20.0,
                ),
              ),
              onRatingUpdate: (rating) {
                if (!NetworkInfo().isServerRecheable()) {
                  AppNotificationManager.of(context).notify(
                    context,
                    title: t.notifications.offline.title,
                    message: t.notifications.offline.message,
                    type: AppNotificationType.danger,
                  );
                  refresh.value = UniqueKey();
                  return;
                }

                isUserTrigger.value = true;
                internalScore.value = rating / 5.0;
                updateScoreDebouncer.run(() async {
                  final newTrack = await trackRepository.setTrackScore(
                    track.id,
                    rating / 5.0,
                  );

                  eventBus.fire(EditTrackEvent(updatedTrack: newTrack));

                  isUserTrigger.value = false;
                });
              },
              glow: false,
            ),
          ),
        ),
      ),
    );
  }

  static double getSize(AppSettingScoringSystem scoringSystem) {
    return switch (scoringSystem) {
      AppSettingScoringSystem.none => 0,
      AppSettingScoringSystem.like => 52,
      AppSettingScoringSystem.stars => 100,
    };
  }
}
