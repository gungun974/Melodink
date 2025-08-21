import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' as riverpod;
import 'package:melodink_client/core/event_bus/event_bus.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_error_box.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/library/data/repository/album_repository.dart';
import 'package:melodink_client/features/library/domain/entities/album.dart';
import 'package:melodink_client/features/library/presentation/viewmodels/create_album_viewmodel.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class CreateAlbumModal extends StatelessWidget {
  const CreateAlbumModal({super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Stack(
        children: [
          AppModal(
            title: Text(t.general.newAlbum),
            body: Form(
              key: context.read<CreateAlbumViewModel>().formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Consumer<CreateAlbumViewModel>(
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
                          AppButtonValueTextField(
                            onTap: () => viewModel.selectArtists(context),
                            labelText: t.general.artists,
                            value: viewModel.artists
                                .map((artist) => artist.name)
                                .join(", "),
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
                            onPressed: () =>
                                viewModel.createAlbum(context, false),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Selector<CreateAlbumViewModel, bool>(
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

  static Future<Album?> showModal(BuildContext context) async {
    final result = await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "CreateAlbumModal",
      pageBuilder: (_, _, _) {
        return Center(
          child: MaxContainer(
            maxWidth: 420,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64),
            child: riverpod.Consumer(
              builder: (context, ref, _) {
                return ChangeNotifierProvider(
                  create: (_) => CreateAlbumViewModel(
                    eventBus: ref.read(eventBusProvider),
                    albumRepository: ref.read(albumRepositoryProvider),
                  ),
                  child: CreateAlbumModal(),
                );
              },
            ),
          ),
        );
      },
    );

    if (result is Album) {
      return result;
    }

    return null;
  }
}
