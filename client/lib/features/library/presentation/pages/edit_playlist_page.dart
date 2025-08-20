import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart' hide ReorderableList;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as riverpod;
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/helpers/auto_close_context_menu_on_scroll.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_error_box.dart';
import 'package:melodink_client/core/widgets/app_navigation_header.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/app_screen_type_layout.dart';
import 'package:melodink_client/core/widgets/auth_cached_network_image.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/sliver_container.dart';
import 'package:melodink_client/features/library/data/repository/playlist_repository.dart';
import 'package:melodink_client/features/library/presentation/hooks/use_dragable_tracks.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/edit_playlist_viewmodel.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/entities/track_compressed_cover_quality.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track.dart';
import 'package:melodink_client/features/track/presentation/widgets/desktop_track_header.dart';
import 'package:melodink_client/features/track/presentation/widgets/track_list.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class PlaylistPageEdit extends riverpod.HookConsumerWidget {
  final int playlistId;

  const PlaylistPageEdit({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final scrollController = useScrollController();

    final scrollViewKey = useMemoized(() => GlobalKey());

    useAutoCloseContextMenuOnScroll(scrollController: scrollController);

    return ChangeNotifierProvider(
      create: (_) => EditPlaylistViewModel(
        eventBus: ref.read(eventBusProvider),
        playlistRepository: ref.read(playlistRepositoryProvider),
      )..loadPlaylist(playlistId),
      child: Stack(
        children: [
          AppNavigationHeader(
            alwayShow: true,
            title: Consumer<EditPlaylistViewModel>(
              builder: (context, viewModel, _) {
                final playlist = viewModel.originalPlaylist;
                if (playlist == null) {
                  return const SizedBox.shrink();
                }
                return Text(t.general.editPlaylist(name: playlist.name));
              },
            ),
            actions: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 24.0),
                    child: Builder(
                      builder: (context) {
                        return AppButton(
                          text: t.general.save,
                          type: AppButtonType.primary,
                          onPressed: () => context
                              .read<EditPlaylistViewModel>()
                              .savePlaylist(context),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
            child: AppScreenTypeLayoutBuilder(
              builder: (context, size) {
                final maxWidth = size == AppScreenTypeLayout.desktop
                    ? 1200
                    : 512;
                final padding = size == AppScreenTypeLayout.desktop
                    ? 24.0
                    : 16.0;

                final separator = size == AppScreenTypeLayout.desktop
                    ? 16.0
                    : 12.0;

                return Form(
                  key: context.read<EditPlaylistViewModel>().formKey,
                  child: HookBuilder(
                    builder: (context) {
                      final vm = context.read<EditPlaylistViewModel>();
                      final (
                        tracks,
                        orderKeys,
                        reorderCallback,
                        reorderDone,
                        dragCancelToken,
                      ) = useDragableTracks(vm.tracks, (List<Track> newTracks) {
                        vm.tracks.value = newTracks;
                      }, []);

                      return ReorderableList(
                        onReorder: reorderCallback,
                        onReorderDone: reorderDone,
                        cancellationToken: dragCancelToken,
                        child: CustomScrollView(
                          key: scrollViewKey,
                          controller: scrollController,
                          slivers: [
                            Selector<EditPlaylistViewModel, bool>(
                              selector: (_, viewModel) => viewModel.hasError,
                              builder: (context, hasError, _) {
                                if (!hasError) {
                                  return SliverToBoxAdapter();
                                }
                                return SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      AppErrorBox(
                                        title: t
                                            .notifications
                                            .somethingWentWrong
                                            .title,
                                        message: t
                                            .notifications
                                            .somethingWentWrong
                                            .message,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                );
                              },
                            ),
                            SliverContainer(
                              maxWidth: maxWidth,
                              padding: EdgeInsets.only(
                                left: padding,
                                right: padding,
                                top: padding,
                                bottom: separator,
                              ),
                              sliver: Consumer<EditPlaylistViewModel>(
                                builder: (context, viewModel, _) {
                                  final playlist = viewModel.originalPlaylist;
                                  if (playlist == null) {
                                    return const SliverToBoxAdapter();
                                  }
                                  final editCoverWidget = Column(
                                    children: [
                                      if (size == AppScreenTypeLayout.desktop)
                                        AuthCachedNetworkImage(
                                          fit: BoxFit.contain,
                                          alignment: Alignment.center,
                                          imageUrl: playlist
                                              .getCompressedCoverUrl(
                                                TrackCompressedCoverQuality
                                                    .high,
                                              ),
                                          placeholder: (context, url) =>
                                              Image.asset(
                                                "assets/melodink_track_cover_not_found.png",
                                              ),
                                          errorWidget: (context, url, error) {
                                            return Image.asset(
                                              "assets/melodink_track_cover_not_found.png",
                                            );
                                          },
                                          width: 256,
                                          height: 256,
                                          gaplessPlayback: true,
                                        ),
                                      if (size == AppScreenTypeLayout.mobile)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 48.0,
                                            vertical: 6.0,
                                          ),
                                          child: AuthCachedNetworkImage(
                                            fit: BoxFit.contain,
                                            imageUrl: playlist
                                                .getCompressedCoverUrl(
                                                  TrackCompressedCoverQuality
                                                      .high,
                                                ),
                                            placeholder: (context, url) =>
                                                Image.asset(
                                                  "assets/melodink_track_cover_not_found.png",
                                                ),
                                            errorWidget: (context, url, error) {
                                              return Image.asset(
                                                "assets/melodink_track_cover_not_found.png",
                                              );
                                            },
                                            gaplessPlayback: true,
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      if (playlist.coverSignature.trim() == "")
                                        Row(
                                          children: [
                                            Expanded(
                                              flex:
                                                  size ==
                                                      AppScreenTypeLayout.mobile
                                                  ? 1
                                                  : 0,
                                              child: SizedBox(
                                                width: 256,
                                                child: AppButton(
                                                  text: t.actions.changeCover,
                                                  type: AppButtonType.secondary,
                                                  onPressed: () => viewModel
                                                      .addCustomCover(context),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (playlist.coverSignature.trim() != "")
                                        Row(
                                          children: [
                                            Expanded(
                                              flex:
                                                  size ==
                                                      AppScreenTypeLayout.mobile
                                                  ? 1
                                                  : 0,
                                              child: SizedBox(
                                                width: 256,
                                                child: AppButton(
                                                  text: t.actions.removeCover,
                                                  type: AppButtonType.secondary,
                                                  onPressed: () => viewModel
                                                      .removeCustomCover(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  );

                                  final editFields = Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppTextFormField(
                                          labelText: t.general.name,
                                          controller:
                                              viewModel.nameTextController,
                                          autovalidateMode:
                                              viewModel.autoValidate
                                              ? AutovalidateMode.always
                                              : AutovalidateMode.disabled,
                                          validator:
                                              FormBuilderValidators.compose([
                                                FormBuilderValidators.required(
                                                  errorText: t.validators
                                                      .fieldShouldNotBeEmpty(
                                                        field: t.general.name,
                                                      ),
                                                ),
                                              ]),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: AppTextFormField(
                                            labelText: t.general.description,
                                            controller: viewModel
                                                .descriptionTextController,
                                            maxLines: null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (size == AppScreenTypeLayout.desktop) {
                                    return SliverToBoxAdapter(
                                      child: IntrinsicHeight(
                                        child: Row(
                                          children: [
                                            editCoverWidget,
                                            const SizedBox(width: 16),
                                            editFields,
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  return SliverToBoxAdapter(
                                    child: IntrinsicHeight(
                                      child: Column(
                                        children: [
                                          editFields,
                                          const SizedBox(height: 16),
                                          editCoverWidget,
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SliverContainer(
                              maxWidth: maxWidth,
                              padding: EdgeInsets.only(
                                left: padding,
                                right: padding,
                              ),
                              sliver: StickyDesktopTrackHeader(
                                modules: [
                                  DesktopTrackModule.remove,
                                  DesktopTrackModule.title,
                                  DesktopTrackModule.album,
                                  DesktopTrackModule.lastPlayed,
                                  DesktopTrackModule.playedCount,
                                  DesktopTrackModule.quality,
                                  DesktopTrackModule.duration,
                                  DesktopTrackModule.score,
                                  DesktopTrackModule.reorderable,
                                ],
                                scrollController: scrollController,
                                scrollViewKey: scrollViewKey,
                              ),
                            ),
                            SliverContainer(
                              maxWidth: maxWidth,
                              padding: EdgeInsets.only(
                                left: padding,
                                right: padding,
                              ),
                              sliver: TrackList(
                                tracks: tracks.value,
                                orderKeys: orderKeys.value,
                                size: size,
                                showTrackIndex: false,
                                showPlayButton: false,
                                modules: const [
                                  DesktopTrackModule.remove,
                                  DesktopTrackModule.title,
                                  DesktopTrackModule.album,
                                  DesktopTrackModule.lastPlayed,
                                  DesktopTrackModule.playedCount,
                                  DesktopTrackModule.quality,
                                  DesktopTrackModule.duration,
                                  DesktopTrackModule.score,
                                  DesktopTrackModule.reorderable,
                                ],
                                playCallback: (_, _) {},
                                showDefaultActions: false,
                                removeCallback: (_, index) {
                                  context
                                      .read<EditPlaylistViewModel>()
                                      .removeTracks({index});
                                },
                                singleCustomActionsBuilder:
                                    (
                                      context,
                                      menuController,
                                      _,
                                      index,
                                      unselect,
                                    ) {
                                      return [
                                        MenuItemButton(
                                          leadingIcon: const AdwaitaIcon(
                                            AdwaitaIcons.list_remove,
                                            size: 20,
                                          ),
                                          child: Text(
                                            t.actions.removeFromPlaylist,
                                          ),
                                          onPressed: () async {
                                            menuController.close();
                                            context
                                                .read<EditPlaylistViewModel>()
                                                .removeTracks({index});
                                            unselect();
                                          },
                                        ),
                                      ];
                                    },
                                multiCustomActionsBuilder:
                                    (
                                      context,
                                      menuController,
                                      _,
                                      selectedIndexes,
                                      unselect,
                                    ) {
                                      return [
                                        MenuItemButton(
                                          leadingIcon: const AdwaitaIcon(
                                            AdwaitaIcons.list_remove,
                                            size: 20,
                                          ),
                                          child: Text(
                                            t.actions.removeFromPlaylist,
                                          ),
                                          onPressed: () {
                                            menuController.close();
                                            context
                                                .read<EditPlaylistViewModel>()
                                                .removeTracks(selectedIndexes);
                                            unselect();
                                          },
                                        ),
                                      ];
                                    },
                                source: "",
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 8),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Selector<EditPlaylistViewModel, bool>(
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
  }
}
