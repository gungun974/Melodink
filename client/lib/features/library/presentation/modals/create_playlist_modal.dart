import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_error_box.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/create_playlist_viewmodel.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class CreatePlaylistModal extends StatelessWidget {
  final List<Track> tracks;

  final bool pushRouteToNewPlaylist;

  const CreatePlaylistModal({
    super.key,
    this.tracks = const [],
    this.pushRouteToNewPlaylist = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Stack(
        children: [
          AppModal(
            title: Text(t.general.newPlaylist),
            body: Form(
              key: context.read<CreatePlaylistViewModel>().formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Consumer<CreatePlaylistViewModel>(
                    builder: (context, viewModel, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextFormField(
                            labelText: t.general.name,
                            controller: viewModel.nameTextController,
                            autovalidateMode: viewModel.autoValidate
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                errorText: t.validators.fieldShouldNotBeEmpty(
                                  field: t.general.name,
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          AppTextFormField(
                            labelText: t.general.description,
                            controller: viewModel.descriptionTextController,
                            maxLines: null,
                          ),
                          const SizedBox(height: 16),
                          if (viewModel.hasError)
                            AppErrorBox(
                              title: t.notifications.somethingWentWrong.title,
                              message:
                                  t.notifications.somethingWentWrong.message,
                            ),
                          if (viewModel.hasError) const SizedBox(height: 16),
                          AppButton(
                            text: t.general.create,
                            type: AppButtonType.primary,
                            onPressed: () => viewModel.createPlaylist(
                              context,
                              tracks,
                              pushRouteToNewPlaylist,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Selector<CreatePlaylistViewModel, bool>(
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

  static void showModal(
    BuildContext context, {
    List<Track> tracks = const [],
    bool pushRouteToNewPlaylist = false,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "CreatePlaylistModal",
      pageBuilder: (_, _, _) {
        return Center(
          child: MaxContainer(
            maxWidth: 420,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64),
            child: ChangeNotifierProvider(
              create: (context) => CreatePlaylistViewModel(
                eventBus: context.read(),
                playlistRepository: context.read(),
              ),
              child: CreatePlaylistModal(
                tracks: tracks,
                pushRouteToNewPlaylist: pushRouteToNewPlaylist,
              ),
            ),
          ),
        );
      },
    );
  }
}
