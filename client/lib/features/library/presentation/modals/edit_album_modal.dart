import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as riverpod;
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/edit_album_viewmodel.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class EditAlbumModal extends StatelessWidget {
  const EditAlbumModal({super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Stack(
        children: [
          AppModal(
            title: Consumer<EditAlbumViewModel>(
              builder: (context, viewModel, _) {
                final album = viewModel.originalAlbum;
                if (album == null) {
                  return const SizedBox.shrink();
                }

                return Text(t.general.editAlbum(name: album.name));
              },
            ),
            body: Form(
              key: context.read<EditAlbumViewModel>().formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Consumer<EditAlbumViewModel>(
                    builder: (context, viewModel, _) {
                      final album = viewModel.originalAlbum;
                      if (album == null) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextFormField(
                            labelText: t.general.trackTitle,
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
                          AppButtonValueTextField(
                            onTap: () => viewModel.selectArtists(context),
                            labelText: t.general.artists,
                            value: viewModel.artists
                                .map((artist) => artist.name)
                                .join(", "),
                          ),
                          const SizedBox(height: 16),
                          if (album.coverSignature.trim() == "")
                            AppButton(
                              text: t.actions.changeCover,
                              type: AppButtonType.secondary,
                              onPressed: () =>
                                  viewModel.addCustomCover(context),
                            ),
                          if (album.coverSignature.trim() != "")
                            AppButton(
                              text: t.actions.removeCover,
                              type: AppButtonType.secondary,
                              onPressed: () =>
                                  viewModel.removeCustomCover(context),
                            ),
                          const SizedBox(height: 16),
                          AppButton(
                            text: t.general.save,
                            type: AppButtonType.primary,
                            onPressed: () => viewModel.saveAlbum(context),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Selector<EditAlbumViewModel, bool>(
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

  static void showModal(BuildContext context, Album album) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "EditAlbumModal",
      pageBuilder: (_, __, ___) {
        return Center(
          child: MaxContainer(
            maxWidth: 420,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
            child: riverpod.Consumer(
              builder: (context, ref, _) {
                return ChangeNotifierProvider(
                  create: (_) => EditAlbumViewModel(
                    eventBus: ref.read(eventBusProvider),
                    albumRepository: ref.read(albumRepositoryProvider),
                  )..loadAlbum(album.id),
                  child: EditAlbumModal(),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
