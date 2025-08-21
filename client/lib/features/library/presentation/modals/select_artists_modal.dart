import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as riverpod;
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/form/app_search_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/library/data/repository/artist_repository.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/select_artists_viewmodel.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class SelectArtistsModal extends StatelessWidget {
  const SelectArtistsModal({super.key});

  @override
  Widget build(BuildContext context) {
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
                        title: Text(t.general.selectArtists),
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
                                      controller: context
                                          .read<SelectArtistsViewModel>()
                                          .searchTextController,
                                      onChanged: (_) => context
                                          .read<SelectArtistsViewModel>()
                                          .updateSearch(),
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
                                    onPressed: () => context
                                        .read<SelectArtistsViewModel>()
                                        .createArtist(context),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                height: targetHeight,
                                child: Scrollbar(
                                  thumbVisibility: true,
                                  child: Consumer<SelectArtistsViewModel>(
                                    builder: (context, viewModel, _) {
                                      if (viewModel.searchArtists.isEmpty) {
                                        return SizedBox.shrink();
                                      }

                                      return ListView.separated(
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                              final artist = viewModel
                                                  .searchArtists[index];

                                              final selected = viewModel
                                                  .selectedIds
                                                  .contains(artist.id);

                                              return ArtistSelector(
                                                artist: artist,
                                                selected: selected,
                                                onSelect: () => viewModel
                                                    .toggleArtist(artist),
                                              );
                                            },
                                        itemCount:
                                            viewModel.searchArtists.length,
                                        separatorBuilder:
                                            (BuildContext context, int index) {
                                              return SizedBox(height: 6);
                                            },
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              AppButton(
                                text: t.general.select,
                                type: AppButtonType.primary,
                                onPressed: () {
                                  context
                                      .read<SelectArtistsViewModel>()
                                      .selectArtists(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Selector<SelectArtistsViewModel, bool>(
                        selector: (_, viewModel) => viewModel.isLoading,
                        builder: (context, isLoading, _) {
                          if (!isLoading) {
                            return const SizedBox.shrink();
                          }
                          return const AppPageLoader();
                        },
                      ),
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

  static Future<List<Artist>?> showModal(
    BuildContext context,
    List<int> defaultSelectedIds,
  ) async {
    final result = await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "SelectArtistsModal",
      pageBuilder: (_, _, _) {
        return Center(
          child: MaxContainer(
            maxWidth: 800,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
            child: riverpod.Consumer(
              builder: (context, ref, _) {
                return ChangeNotifierProvider(
                  create: (_) => SelectArtistsViewModel(
                    eventBus: ref.read(eventBusProvider),
                    artistRepository: ref.read(artistRepositoryProvider),
                  )..loadArtists(defaultSelectedIds),
                  child: SelectArtistsModal(),
                );
              },
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
