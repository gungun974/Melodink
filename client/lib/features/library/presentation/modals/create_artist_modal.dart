import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_error_box.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_notification_manager.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/library/domain/providers/create_artist_provider.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class CreateArtistModal extends HookConsumerWidget {
  const CreateArtistModal({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final autoValidate = useState(false);

    final isLoading = useState(false);

    final hasError = useState(false);

    final nameTextController = useTextEditingController();

    return IntrinsicHeight(
      child: Stack(
        children: [
          AppModal(
            title: Text(t.general.newArtist),
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextFormField(
                        labelText: t.general.name,
                        controller: nameTextController,
                        autovalidateMode: autoValidate.value
                            ? AutovalidateMode.always
                            : AutovalidateMode.disabled,
                        validator: FormBuilderValidators.compose(
                          [
                            FormBuilderValidators.required(
                              errorText: t.validators.fieldShouldNotBeEmpty(
                                field: t.general.name,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (hasError.value)
                        AppErrorBox(
                          title: t.notifications.somethingWentWrong.title,
                          message: t.notifications.somethingWentWrong.message,
                        ),
                      if (hasError.value) const SizedBox(height: 16),
                      AppButton(
                        text: t.general.create,
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
                            final newArtist = await ref
                                .read(createArtistStreamProvider.notifier)
                                .createArtist(Artist(
                                  id: -1,
                                  name: nameTextController.text,
                                  albums: [],
                                  appearAlbums: [],
                                  hasRoleAlbums: [],
                                ));

                            isLoading.value = false;

                            if (!context.mounted) {
                              return;
                            }

                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pop(newArtist);

                            AppNotificationManager.of(context).notify(
                              context,
                              message:
                                  t.notifications.artistHaveBeenCreated.message(
                                name: newArtist.name,
                              ),
                            );
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

  static Future<Artist?> showModal(BuildContext context) async {
    final result = await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "CreateArtistModal",
      pageBuilder: (_, __, ___) {
        return Center(
          child: MaxContainer(
            maxWidth: 420,
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 64,
            ),
            child: CreateArtistModal(),
          ),
        );
      },
    );

    if (result is Artist) {
      return result;
    }

    return null;
  }
}
