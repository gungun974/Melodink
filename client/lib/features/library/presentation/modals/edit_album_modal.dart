import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/helpers/app_confirm.dart';
import 'package:melodink_client/core/helpers/pick_audio_files.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/domain/providers/edit_album_provider.dart';
import 'package:melodink_client/features/library/presentation/modals/manage_album_artists_modal.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class EditAlbumModal extends HookConsumerWidget {
  final Album album;

  const EditAlbumModal({
    super.key,
    required this.album,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final isLoading = useState(false);

    final refreshKey = useState(0);

    final fetchSignature = useMemoized(
      () =>
          AppApi().dio.get<String>("/album/${album.id}/cover/custom/signature"),
      [refreshKey.value],
    );

    final coverSignature = useFuture(fetchSignature, preserveState: false).data;

    final currentArtists = useState(album.artists);

    return IntrinsicHeight(
      child: Stack(
        children: [
          AppModal(
            title: Text(
              t.general.editAlbum(name: album.name),
            ),
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton(
                        text: t.actions.changeArtists,
                        type: AppButtonType.secondary,
                        onPressed: () async {
                          final artists =
                              await ManageAlbumArtistsModal.showModal(
                            context,
                            album,
                            currentArtists.value
                                .map(
                                  (artist) => artist.id,
                                )
                                .toList(),
                          );

                          if (artists == null) {
                            return;
                          }

                          currentArtists.value = artists;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (coverSignature?.data?.trim() == "")
                        AppButton(
                          text: t.actions.changeCover,
                          type: AppButtonType.secondary,
                          onPressed: () async {
                            final file = await pickImageFile();

                            if (file == null) {
                              return;
                            }

                            isLoading.value = true;
                            try {
                              await ref
                                  .read(editAlbumStreamProvider.notifier)
                                  .changeAlbumCover(album.id, file);
                              isLoading.value = false;
                            } catch (_) {
                              isLoading.value = false;

                              if (context.mounted) {
                                AppNotificationManager.of(context).notify(
                                  context,
                                  title:
                                      t.notifications.somethingWentWrong.title,
                                  message: t
                                      .notifications.somethingWentWrong.message,
                                  type: AppNotificationType.danger,
                                );
                              }
                              rethrow;
                            }

                            refreshKey.value += 1;

                            if (!context.mounted) {
                              return;
                            }

                            AppNotificationManager.of(context).notify(
                              context,
                              message: t.notifications.albumCoverHaveBeenChanged
                                  .message(
                                name: album.name,
                              ),
                            );
                          },
                        ),
                      if (coverSignature?.data?.trim() != "")
                        AppButton(
                          text: t.actions.removeCover,
                          type: AppButtonType.secondary,
                          onPressed: () async {
                            if (!await appConfirm(
                              context,
                              title: t.confirms.title,
                              content: t.confirms.removeCustomCover,
                              textOK: t.confirms.confirm,
                            )) {
                              return;
                            }

                            isLoading.value = true;
                            try {
                              await ref
                                  .read(editAlbumStreamProvider.notifier)
                                  .removeAlbumCover(album.id);
                              isLoading.value = false;
                            } catch (_) {
                              isLoading.value = false;

                              if (context.mounted) {
                                AppNotificationManager.of(context).notify(
                                  context,
                                  title:
                                      t.notifications.somethingWentWrong.title,
                                  message: t
                                      .notifications.somethingWentWrong.message,
                                  type: AppNotificationType.danger,
                                );
                              }
                              rethrow;
                            }

                            refreshKey.value += 1;

                            if (!context.mounted) {
                              return;
                            }

                            AppNotificationManager.of(context).notify(
                              context,
                              message: t.notifications.albumCoverHaveBeenRemoved
                                  .message(
                                name: album.name,
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: t.general.save,
                        type: AppButtonType.primary,
                        onPressed: () async {
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop();

                          AppNotificationManager.of(context).notify(
                            context,
                            message: t.notifications.albumHaveBeenSaved.message(
                              name: album.name,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isLoading.value || coverSignature == null) const AppPageLoader(),
        ],
      ),
    );
  }

  static showModal(
    BuildContext context,
    Album album,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "EditAlbumModal",
      pageBuilder: (_, __, ___) {
        return Center(
          child: MaxContainer(
            maxWidth: 420,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 64,
            ),
            child: EditAlbumModal(album: album),
          ),
        );
      },
    );
  }
}
