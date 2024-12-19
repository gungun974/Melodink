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

    return IntrinsicHeight(
      child: Stack(
        children: [
          AppModal(
            title: Text("Edit album \"${album.name}\""),
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (coverSignature?.data?.trim() == "")
                        AppButton(
                          text: "Change Cover",
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
                                  title: "Error",
                                  message: "Something went wrong",
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
                              message:
                                  "The cover for album \"${album.name}\" have been changed.",
                            );
                          },
                        ),
                      if (coverSignature?.data?.trim() != "")
                        AppButton(
                          text: "Remove Cover",
                          type: AppButtonType.secondary,
                          onPressed: () async {
                            if (!await appConfirm(
                              context,
                              title: "Confirm",
                              content:
                                  "Would you like to remove the custom cover ?'",
                              textOK: "Confirm",
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
                                  title: "Error",
                                  message: "Something went wrong",
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
                              message:
                                  "The cover for album \"${album.name}\" have been removed.",
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: "Save",
                        type: AppButtonType.primary,
                        onPressed: () async {
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop();

                          AppNotificationManager.of(context).notify(
                            context,
                            message: "Album \"${album.name}\" have been saved",
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
