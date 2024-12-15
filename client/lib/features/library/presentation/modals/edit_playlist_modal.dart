import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_error_box.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/library/domain/entities/playlist.dart';
import 'package:melodink_client/features/library/domain/providers/create_playlist_provider.dart';
import 'package:melodink_client/features/library/domain/providers/edit_playlist_provider.dart';

class EditPlaylistModal extends HookConsumerWidget {
  final Playlist playlist;

  const EditPlaylistModal({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final autoValidate = useState(false);

    final isLoading = useState(false);

    final hasError = useState(false);

    final nameTextController = useTextEditingController(
      text: playlist.name,
    );

    final descriptionTextController = useTextEditingController(
      text: playlist.description,
    );

    return IntrinsicHeight(
      child: Stack(
        children: [
          AppModal(
            title: Text("Edit playlist \"${playlist.name}\""),
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextFormField(
                        labelText: "Name",
                        controller: nameTextController,
                        autovalidateMode: autoValidate.value
                            ? AutovalidateMode.always
                            : AutovalidateMode.disabled,
                        validator: FormBuilderValidators.compose(
                          [
                            FormBuilderValidators.required(
                              errorText: "Name should not be empty.",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppTextFormField(
                        labelText: "Description",
                        controller: descriptionTextController,
                        maxLines: null,
                      ),
                      const SizedBox(height: 16),
                      if (hasError.value)
                        const AppErrorBox(
                          title: "Error",
                          message: "Something went wrong",
                        ),
                      if (hasError.value) const SizedBox(height: 16),
                      AppButton(
                        text: "Save",
                        type: AppButtonType.primary,
                        onPressed: () async {
                          hasError.value = false;
                          final currentState = formKey.currentState;
                          if (currentState == null) {
                            return;
                          }

                          if (!currentState.validate()) {
                            autoValidate.value = true;
                            return;
                          }

                          isLoading.value = true;

                          try {
                            ref
                                .read(editPlaylistStreamProvider.notifier)
                                .savePlaylist(Playlist(
                                  id: playlist.id,
                                  name: nameTextController.text,
                                  description: descriptionTextController.text,
                                  tracks: const [],
                                ));

                            isLoading.value = false;

                            if (!context.mounted) {
                              return;
                            }

                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pop();
                          } catch (_) {
                            isLoading.value = false;
                            hasError.value = true;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isLoading.value) const AppPageLoader(),
        ],
      ),
    );
  }

  static showModal(
    BuildContext context,
    Playlist playlist,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "EditPlaylistModal",
      pageBuilder: (_, __, ___) {
        return Center(
          child: MaxContainer(
            maxWidth: 420,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 64,
            ),
            child: EditPlaylistModal(playlist: playlist),
          ),
        );
      },
    );
  }
}
