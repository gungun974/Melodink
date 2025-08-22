import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_error_box.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/form/app_datetime_form_field.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/max_container.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/presentation/viewmodels/edit_track_viewmodel.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class EditTrackModal extends HookWidget {
  final Track track;

  final bool displayDateAdded;

  const EditTrackModal({
    super.key,
    required this.track,
    this.displayDateAdded = true,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Stack(
        children: [
          AppModal(
            preventUserClose: true,
            title: Text(t.general.editTrack(title: track.title)),
            body: Form(
              key: context.read<EditTrackViewModel>().formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Consumer<EditTrackViewModel>(
                    builder: (context, viewModel, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextFormField(
                            labelText: t.general.trackTitle,
                            controller: viewModel.titleTextController,
                            autovalidateMode: viewModel.autoValidate
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                errorText: t.validators.fieldShouldNotBeEmpty(
                                  field: t.general.trackTitle,
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          AppButtonValueTextField(
                            onTap: () => viewModel.selectAlbums(context),
                            labelText: t.general.album,
                            value: viewModel.albums
                                .map((album) => album.name)
                                .join(", "),
                          ),
                          const SizedBox(height: 8),
                          AppButtonValueTextField(
                            onTap: () => viewModel.selectArtists(context),
                            labelText: t.general.artists,
                            value: viewModel.artists
                                .map((artist) => artist.name)
                                .join(", "),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextFormField(
                                  labelText: t.general.trackNumber,
                                  controller:
                                      viewModel.trackNumberTextController,
                                  autovalidateMode: viewModel.autoValidate
                                      ? AutovalidateMode.always
                                      : AutovalidateMode.disabled,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.integer(
                                      errorText: t.validators.fieldShouldBeInt(
                                        field: t.general.trackNumber,
                                      ),
                                    ),
                                    FormBuilderValidators.min(
                                      0,
                                      errorText: t.validators
                                          .fieldShouldBeGreaterOrEqualZero(
                                            field: t.general.trackNumber,
                                          ),
                                    ),
                                  ]),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppTextFormField(
                                  labelText: t.general.totalTracks,
                                  controller:
                                      viewModel.totalTracksTextController,
                                  autovalidateMode: viewModel.autoValidate
                                      ? AutovalidateMode.always
                                      : AutovalidateMode.disabled,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.integer(
                                      errorText: t.validators.fieldShouldBeInt(
                                        field: t.general.totalTracks,
                                      ),
                                    ),
                                    FormBuilderValidators.min(
                                      0,
                                      errorText: t.validators
                                          .fieldShouldBeGreaterOrEqualZero(
                                            field: t.general.totalTracks,
                                          ),
                                    ),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextFormField(
                                  labelText: t.general.trackDisc,
                                  controller:
                                      viewModel.discNumberTextController,
                                  autovalidateMode: viewModel.autoValidate
                                      ? AutovalidateMode.always
                                      : AutovalidateMode.disabled,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.integer(
                                      errorText: t.validators.fieldShouldBeInt(
                                        field: t.general.trackDisc,
                                      ),
                                    ),
                                    FormBuilderValidators.min(
                                      0,
                                      errorText: t.validators
                                          .fieldShouldBeGreaterOrEqualZero(
                                            field: t.general.trackDisc,
                                          ),
                                    ),
                                  ]),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppTextFormField(
                                  labelText: t.general.totalDiscs,
                                  controller:
                                      viewModel.totalDiscsTextController,
                                  autovalidateMode: viewModel.autoValidate
                                      ? AutovalidateMode.always
                                      : AutovalidateMode.disabled,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.integer(
                                      errorText: t.validators.fieldShouldBeInt(
                                        field: t.general.totalDiscs,
                                      ),
                                    ),
                                    FormBuilderValidators.min(
                                      0,
                                      errorText: t.validators
                                          .fieldShouldBeGreaterOrEqualZero(
                                            field: t.general.totalDiscs,
                                          ),
                                    ),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          AppTextFormField(
                            labelText: t.general.date,
                            controller: viewModel.dateTextController,
                          ),
                          const SizedBox(height: 8),
                          AppTextFormField(
                            labelText: t.general.year,
                            controller: viewModel.yearTextController,
                            autovalidateMode: viewModel.autoValidate
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.integer(
                                errorText: t.validators.fieldShouldBeInt(
                                  field: t.general.year,
                                ),
                              ),
                              FormBuilderValidators.min(
                                -1,
                                errorText: t.validators
                                    .fieldShouldBeGreaterOrEqual(
                                      field: t.general.year,
                                      n: -1,
                                    ),
                              ),
                            ]),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Text(
                                t.general.genres,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 20,
                                  letterSpacing: 20 * 0.04,
                                ),
                              ),
                              AppIconButton(
                                icon: const AdwaitaIcon(AdwaitaIcons.list_add),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                iconSize: 20,
                                onPressed: () {
                                  viewModel.addGenre();
                                },
                              ),
                            ],
                          ),
                          if (viewModel.genres.isNotEmpty)
                            const SizedBox(height: 8),
                          Column(
                            children: viewModel.genres.indexed.expand((
                              entry,
                            ) sync* {
                              yield AppValueTextField(
                                labelText: t.general.genre,
                                value: entry.$2,
                                suffixIcon: const AdwaitaIcon(
                                  size: 20,
                                  AdwaitaIcons.list_remove,
                                ),
                                suffixIconOnPressed: () =>
                                    viewModel.removeGenre(entry.$1),
                                onChanged: (value) =>
                                    viewModel.updateGenre(entry.$1, value),
                                autovalidateMode: viewModel.autoValidate
                                    ? AutovalidateMode.always
                                    : AutovalidateMode.disabled,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(
                                    errorText: t.validators
                                        .fieldShouldNotBeEmpty(
                                          field: t.general.genre,
                                        ),
                                  ),
                                ]),
                              );
                              if (entry.$1 < viewModel.genres.length - 1) {
                                yield const SizedBox(height: 8);
                              }
                            }).toList(),
                          ),
                          const Divider(height: 24),
                          AppTextFormField(
                            labelText: "AcoustId",
                            controller: viewModel.acoustIdTextController,
                          ),
                          const SizedBox(height: 8),
                          AppTextFormField(
                            labelText: t.general.musicBrainzReleaseId,
                            controller:
                                viewModel.musicBrainzReleaseIdTextController,
                          ),
                          const SizedBox(height: 8),
                          AppTextFormField(
                            labelText: t.general.musicBrainzTrackId,
                            controller:
                                viewModel.musicBrainzTrackIdTextController,
                          ),
                          const SizedBox(height: 8),
                          AppTextFormField(
                            labelText: t.general.musicBrainzRecordingId,
                            controller:
                                viewModel.musicBrainzRecordingIdTextController,
                          ),
                          const Divider(height: 24),
                          AppTextFormField(
                            labelText: t.general.composer,
                            controller: viewModel.composerTextController,
                          ),
                          const SizedBox(height: 8),
                          AppTextFormField(
                            labelText: t.general.comment,
                            controller: viewModel.commentTextController,
                          ),
                          if (displayDateAdded) const Divider(height: 24),
                          if (displayDateAdded)
                            AppDatetimeFormField(
                              labelText: t.general.dateAdded,
                              formatter: DateFormat.yMd().add_Hm(),
                              value: viewModel.dateAdded,
                              onChanged: (value) {
                                viewModel.dateAdded = value;
                              },
                            ),
                          const Divider(height: 24),
                          ExpansionTile(
                            shape: const Border(),
                            tilePadding: const EdgeInsets.all(0),
                            title: Text(
                              t.general.lyrics,
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 20,
                                letterSpacing: 20 * 0.04,
                                color: Colors.white,
                              ),
                            ),
                            children: [
                              AppTextFormField(
                                labelText: t.general.lyrics,
                                controller: viewModel.lyricsTextController,
                                maxLines: null,
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: t.actions.changeAudio,
                                  type: AppButtonType.secondary,
                                  onPressed: () =>
                                      viewModel.changeAudio(context),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppButton(
                                  text: t.actions.changeCover,
                                  type: AppButtonType.secondary,
                                  onPressed: () =>
                                      viewModel.changeCover(context),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppButton(
                                  text: t.actions.scanMetadata,
                                  type: AppButtonType.secondary,
                                  onPressed: () =>
                                      viewModel.scanAudioFile(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (viewModel.hasError)
                            AppErrorBox(
                              title: t.notifications.somethingWentWrong.title,
                              message:
                                  t.notifications.somethingWentWrong.message,
                            ),
                          if (viewModel.hasError) const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: t.general.cancel,
                                  type: AppButtonType.danger,
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppButton(
                                  text: t.general.save,
                                  type: AppButtonType.primary,
                                  onPressed: () => viewModel.save(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Selector<EditTrackViewModel, bool>(
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
    BuildContext context,
    Track track, {
    bool displayDateAdded = true,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "EditTrackModal",
      pageBuilder: (_, _, _) {
        return Center(
          child: MaxContainer(
            maxWidth: 800,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 64),
            child: ChangeNotifierProvider(
              create: (context) => EditTrackViewModel(
                eventBus: context.read(),
                trackRepository: context.read(),
              )..loadTrack(track),
              child: EditTrackModal(
                track: track,
                displayDateAdded: displayDateAdded,
              ),
            ),
          ),
        );
      },
    );
  }
}
