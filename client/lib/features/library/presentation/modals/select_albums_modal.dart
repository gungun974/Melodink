import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/helpers/fuzzy_search.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/form/app_search_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/presentation/modals/create_album_modal.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class SelectAlbumsModal extends HookConsumerWidget {
  final List<int> currentIds;

  const SelectAlbumsModal({super.key, required this.currentIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumRepository = ref.read(albumRepositoryProvider);

    final isLoading = useState(false);

    final searchTextController = useTextEditingController(text: "");

    final albums = useState<List<Album>>([]);

    final filteredAlbums = useState<List<Album>>([]);

    final selectedIds = useState<List<int>>([...currentIds]);

    applySearch() {
      if (searchTextController.text.isEmpty) {
        filteredAlbums.value = albums.value;
      }
      filteredAlbums.value =
          albums.value.where((album) {
            if (selectedIds.value.contains(album.id)) {
              return true;
            }

            final buffer = StringBuffer();

            buffer.write(album.name);

            for (final artist in album.artists) {
              buffer.write(artist.name);
            }

            return compareFuzzySearch(
              searchTextController.text,
              buffer.toString(),
            );
          }).toList()..sort(
            (a, b) =>
                (currentIds.contains(b.id) ? 1 : 0) -
                (currentIds.contains(a.id) ? 1 : 0),
          );
    }

    loadAlbums() async {
      isLoading.value = true;
      try {
        final newAlbums = await albumRepository.getAllAlbums();
        albums.value = newAlbums;
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      loadAlbums();

      return null;
    }, []);

    useEffect(() {
      applySearch();
      return null;
    }, [albums.value]);

    return MaxContainer(
      maxWidth: 440,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
      child: Stack(
        children: [
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double available = constraints.maxHeight;

                final double targetHeight = available.isFinite
                    ? available - 200
                    : 200;

                return IntrinsicHeight(
                  child: Stack(
                    children: [
                      AppModal(
                        preventUserClose: true,
                        title: Text(t.general.editTrackAlbum),
                        body: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: AppSearchFormField(
                                      controller: searchTextController,
                                      onChanged: (value) {
                                        applySearch();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  AppIconButton(
                                    iconSize: 40,
                                    icon: Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                          196,
                                          126,
                                          208,
                                          1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          10.0,
                                        ),
                                      ),
                                      child: Center(
                                        child: AdwaitaIcon(
                                          size: 20,
                                          AdwaitaIcons.list_add,
                                        ),
                                      ),
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      final album =
                                          await CreateAlbumModal.showModal(
                                            context,
                                          );

                                      if (album == null) {
                                        return;
                                      }

                                      await loadAlbums();

                                      selectedIds.value = [album.id];

                                      applySearch();
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                height: targetHeight,
                                child: Scrollbar(
                                  thumbVisibility: true,
                                  child: ListView.separated(
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                          final album =
                                              filteredAlbums.value[index];

                                          final selected = selectedIds.value
                                              .contains(album.id);

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
                                    itemCount: filteredAlbums.value.length,
                                    separatorBuilder:
                                        (BuildContext context, int index) {
                                          return SizedBox(height: 6);
                                        },
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              AppButton(
                                text: t.general.save,
                                type: AppButtonType.primary,
                                onPressed: () {
                                  final selectedAlbums = albums.value
                                      .where(
                                        (album) => selectedIds.value.contains(
                                          album.id,
                                        ),
                                      )
                                      .toList();

                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop(selectedAlbums);
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
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<List<Album>?> showModal(
    BuildContext context,
    List<int> currentIds,
  ) async {
    final result = await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "SelectAlbumsModal",
      pageBuilder: (_, _, _) {
        return Center(
          child: MaxContainer(
            maxWidth: 800,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
            child: SelectAlbumsModal(currentIds: currentIds),
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
                      ),
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
