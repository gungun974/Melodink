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
import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/library/presentation/modals/create_artist_modal.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class ManageTrackArtistsModal extends HookConsumerWidget {
  final Track track;

  final List<int> currentIds;

  const ManageTrackArtistsModal({
    super.key,
    required this.track,
    required this.currentIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackRepository = ref.read(trackRepositoryProvider);
    final artistRepository = ref.read(artistRepositoryProvider);

    final isLoading = useState(false);

    final searchTextController = useTextEditingController(
      text: "",
    );

    final artists = useState<List<Artist>>([]);

    final filteredArtists = useState<List<Artist>>([]);

    final selectedIds = useState<List<int>>(
      [...currentIds],
    );

    applySearch() {
      if (searchTextController.text.isEmpty) {
        filteredArtists.value = artists.value;
      }
      filteredArtists.value = artists.value.where((artist) {
        if (selectedIds.value.contains(artist.id)) {
          return true;
        }
        return compareFuzzySearch(searchTextController.text, artist.name);
      }).toList()
        ..sort(
          (a, b) =>
              (currentIds.contains(b.id) ? 1 : 0) -
              (currentIds.contains(a.id) ? 1 : 0),
        );
    }

    loadArtists() async {
      isLoading.value = true;
      try {
        final newArtists = await artistRepository.getAllArtists();
        artists.value = newArtists;
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      loadArtists();

      return null;
    }, []);

    useEffect(() {
      applySearch();
      return null;
    }, [artists.value]);

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
                        t.general.editTrackArtists,
                      ),
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
                                      borderRadius: BorderRadius.circular(10.0),
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
                                    final artist =
                                        await CreateArtistModal.showModal(
                                      context,
                                    );

                                    if (artist == null) {
                                      return;
                                    }

                                    await loadArtists();

                                    selectedIds.value = [
                                      ...selectedIds.value,
                                      artist.id
                                    ];

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
                                    final artist = filteredArtists.value[index];

                                    final selected = selectedIds.value.contains(
                                      artist.id,
                                    );

                                    return ArtistSelector(
                                      artist: artist,
                                      selected: selected,
                                      onSelect: () {
                                        if (selected) {
                                          selectedIds.value = selectedIds.value
                                              .where((id) => id != artist.id)
                                              .toList();
                                          return;
                                        }
                                        selectedIds.value = [
                                          ...selectedIds.value,
                                          artist.id
                                        ];
                                      },
                                    );
                                  },
                                  itemCount: filteredArtists.value.length,
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
                                  final savedArtists = artists.value
                                      .where((album) =>
                                          selectedIds.value.contains(album.id))
                                      .toList();

                                  await trackRepository.setTrackArtists(
                                    track.id,
                                    savedArtists,
                                  );

                                  ref.invalidate(trackByIdProvider(track.id));

                                  isLoading.value = false;

                                  if (!context.mounted) {
                                    return;
                                  }

                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop(savedArtists);
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

  static Future<List<Artist>?> showModal(
    BuildContext context,
    Track track,
    List<int> currentIds,
  ) async {
    final result = await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "ManageTrackArtistsModal",
      pageBuilder: (_, __, ___) {
        return Center(
          child: MaxContainer(
            maxWidth: 800,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 64,
            ),
            child: ManageTrackArtistsModal(
              track: track,
              currentIds: currentIds,
            ),
          ),
        );
      },
    );

    if (result is List<Artist>) {
      return result;
    }

    return null;
  }
}

class ArtistSelector extends StatelessWidget {
  final Artist artist;

  final bool selected;

  final void Function() onSelect;

  const ArtistSelector({
    super.key,
    required this.artist,
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
                    imageUrl: artist.getCompressedCoverUrl(
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
                  child: Tooltip(
                    message: artist.name,
                    waitDuration: const Duration(milliseconds: 800),
                    child: Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        letterSpacing: 14 * 0.03,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
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
