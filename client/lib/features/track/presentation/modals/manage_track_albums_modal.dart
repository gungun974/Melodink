import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/form/app_search_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class ManageTrackAlbumsModal extends HookConsumerWidget {
  final Track track;

  final List<int> currentIds;

  const ManageTrackAlbumsModal({
    super.key,
    required this.track,
    required this.currentIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackRepository = ref.read(trackRepositoryProvider);
    final albumRepository = ref.read(albumRepositoryProvider);

    final isLoading = useState(false);

    final searchTextController = useTextEditingController(
      text: "",
    );

    final albums = useState<List<Album>>([]);

    final selectedIds = useState<List<int>>([...currentIds]);

    useEffect(() {
      isLoading.value = true;
      albumRepository.getAllAlbums().then((newAlbums) {
        albums.value = newAlbums;
        isLoading.value = false;
      }).catchError((_) {
        isLoading.value = false;
      });

      return null;
    }, []);

    return MaxContainer(
      maxWidth: 440,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 64,
      ),
      child: Stack(
        children: [
          Center(
            child: LayoutBuilder(builder: (context, constraints) {
              final double available = constraints.maxHeight;

              final double targetHeight =
                  available.isFinite ? available - 200 : 200;

              return IntrinsicHeight(
                child: Stack(
                  children: [
                    AppModal(
                      preventUserClose: true,
                      title: Text(
                        "Manage track album",
                      ),
                      body: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppSearchFormField(
                              controller: searchTextController,
                              onChanged: (value) {},
                            ),
                            SizedBox(height: 8),
                            SizedBox(
                              height: targetHeight,
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: ListView.separated(
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final album = albums.value[index];

                                    final selected = selectedIds.value.contains(
                                      album.id,
                                    );

                                    return AlbumSelector(
                                      album: album,
                                      selected: selected,
                                      onSelect: () {
                                        if (selected) {
                                          selectedIds.value = [];
                                          return;
                                        }
                                        selectedIds.value = [album.id];
                                      },
                                    );
                                  },
                                  itemCount: albums.value.length,
                                  separatorBuilder:
                                      (BuildContext context, int index) {
                                    return SizedBox(
                                      height: 6,
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            AppButton(
                              text: t.general.save,
                              type: AppButtonType.primary,
                              onPressed: () async {
                                isLoading.value = true;

                                try {
                                  final savedAlbums = albums.value
                                      .where((album) =>
                                          selectedIds.value.contains(album.id))
                                      .toList();

                                  await trackRepository.setTrackAlbums(
                                    track.id,
                                    savedAlbums,
                                  );

                                  ref.invalidate(trackByIdProvider(track.id));

                                  isLoading.value = false;

                                  if (!context.mounted) {
                                    return;
                                  }

                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop(savedAlbums);
                                } catch (_) {
                                  isLoading.value = false;
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isLoading.value) const AppPageLoader(),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  static Future<List<Album>?> showModal(
    BuildContext context,
    Track track,
    List<int> currentIds,
  ) async {
    final result = await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "ManageTrackAlbumsModal",
      pageBuilder: (_, __, ___) {
        return Center(
          child: MaxContainer(
            maxWidth: 800,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 64,
            ),
            child: ManageTrackAlbumsModal(
              track: track,
              currentIds: currentIds,
            ),
          ),
        );
      },
    );

    if (result is List<Album>) {
      return result;
    }

    return null;
  }
}

class AlbumSelector extends StatelessWidget {
  final Album album;

  final bool selected;

  final void Function() onSelect;

  const AlbumSelector({
    super.key,
    required this.album,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          child: Container(
            height: 48,
            color: Colors.transparent,
            child: Row(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: AuthCachedNetworkImage(
                    fit: BoxFit.contain,
                    imageUrl: album.getCompressedCoverUrl(
                      TrackCompressedCoverQuality.small,
                    ),
                    placeholder: (context, url) => Image.asset(
                      "assets/melodink_track_cover_not_found.png",
                    ),
                    errorWidget: (context, url, error) {
                      return Image.asset(
                        "assets/melodink_track_cover_not_found.png",
                      );
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: album.name,
                        waitDuration: const Duration(milliseconds: 800),
                        child: Text(
                          album.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            letterSpacing: 14 * 0.03,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Tooltip(
                              message: album.artists
                                  .map((artist) => artist.name)
                                  .join(", "),
                              waitDuration: const Duration(milliseconds: 800),
                              child: Text(
                                album.artists
                                    .map((artist) => artist.name)
                                    .join(", "),
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
                        ],
                      )
                    ],
                  ),
                ),
                Radio(
                  value: true,
                  toggleable: true,
                  groupValue: selected,
                  onChanged: (_) {
                    onSelect();
                  },
                ),
              ],
            ),
          ),
          onTap: () {
            onSelect();
          },
        ),
      ),
    );
  }
}
