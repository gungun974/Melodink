import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';

class AllTrackFilterPanel extends ConsumerWidget {
  const AllTrackFilterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncArtistsOptions =
        ref.watch(allTracksArtistFiltersOptionsProvider);

    final allTracksArtistsSelectedOptions =
        ref.watch(allTracksArtistsSelectedOptionsProvider);

    final asyncAlbumsOptions = ref.watch(allTracksAlbumFiltersOptionsProvider);

    final allTracksAlbumsSelectedOptions =
        ref.watch(allTracksAlbumsSelectedOptionsProvider);

    final artistsOptions = asyncArtistsOptions.valueOrNull;

    if (artistsOptions == null) {
      return const SizedBox.shrink();
    }

    final albumsOptions = asyncAlbumsOptions.valueOrNull;

    if (albumsOptions == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 0, 0, 0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        height: 250,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AllTrackFilterCategory(
              title: "Artist",
              options: artistsOptions.map((artist) => artist.name).toList(),
              selectedOptions: artistsOptions.indexed
                  .where(
                    (value) =>
                        allTracksArtistsSelectedOptions.contains(value.$2.id),
                  )
                  .map((value) => value.$1)
                  .toList(),
              selectOption: (index) {
                if (index == -1) {
                  ref
                      .read(allTracksArtistsSelectedOptionsProvider.notifier)
                      .state = [];
                  return;
                }

                final artist = artistsOptions[index];

                ref
                    .read(allTracksArtistsSelectedOptionsProvider.notifier)
                    .state = [artist.id];
              },
            ),
            const SizedBox(width: 12),
            AllTrackFilterCategory(
              title: "Album",
              options: albumsOptions.map((album) => album.$2).toList(),
              selectedOptions: albumsOptions.indexed
                  .where(
                    (value) =>
                        allTracksAlbumsSelectedOptions.contains(value.$2.$1),
                  )
                  .map((value) => value.$1)
                  .toList(),
              selectOption: (index) {
                if (index == -1) {
                  ref
                      .read(allTracksAlbumsSelectedOptionsProvider.notifier)
                      .state = [];
                  return;
                }

                final album = albumsOptions[index];

                ref
                    .read(allTracksAlbumsSelectedOptionsProvider.notifier)
                    .state = [album.$1];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AllTrackFilterCategory extends HookWidget {
  final String title;

  final List<String> options;

  final List<int> selectedOptions;

  final void Function(int index) selectOption;

  const AllTrackFilterCategory({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOptions,
    required this.selectOption,
  });

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();

    useEffect(() {
      if (!scrollController.hasClients) {
        return null;
      }

      if (selectedOptions.isEmpty) {
        scrollController.jumpTo(0);
        return null;
      }

      final targetPosition = (selectedOptions.first + 1) * 24;

      if (scrollController.offset > targetPosition ||
          targetPosition >
              scrollController.offset +
                  scrollController.position.viewportDimension) {
        scrollController.jumpTo(
          targetPosition - scrollController.position.viewportDimension / 2 + 12,
        );
      }

      return null;
    }, [selectedOptions]);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 0, 0, 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  letterSpacing: 14 * 0.03,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemExtent: 24,
                itemBuilder: (BuildContext context, int index) {
                  return HookBuilder(builder: (context) {
                    final isHovering = useState(false);

                    return MouseRegion(
                      onEnter: (_) {
                        isHovering.value = true;
                      },
                      onExit: (_) {
                        isHovering.value = false;
                      },
                      child: GestureDetector(
                        onTap: () {
                          selectOption(index - 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          color: (selectedOptions.contains(index - 1) ||
                                  (index == 0 && selectedOptions.isEmpty))
                              ? const Color.fromRGBO(0, 0, 0, 0.075)
                              : (isHovering.value
                                  ? const Color.fromRGBO(0, 0, 0, 0.05)
                                  : Colors.transparent),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: index == 0
                                ? const Text(
                                    "All",
                                    style: TextStyle(
                                        fontSize: 12,
                                        letterSpacing: 14 * 0.03,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500),
                                  )
                                : Text(
                                    options[index - 1],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      letterSpacing: 14 * 0.03,
                                      color: Colors.grey[350],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  });
                },
                itemCount: options.length + 1,
              ),
            )
          ],
        ),
      ),
    );
  }
}
