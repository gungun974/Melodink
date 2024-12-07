import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_error_box.dart';
import 'package:melodink_client/core/widgets/app_icon_button.dart';
import 'package:melodink_client/core/widgets/app_modal.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/form/app_datetime_form_field.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/features/library/domain/entities/artist.dart';
import 'package:melodink_client/features/track/data/repository/track_repository.dart';
import 'package:melodink_client/features/track/domain/entities/track.dart';
import 'package:melodink_client/features/track/domain/providers/track_provider.dart';

class EditTrackModal extends HookConsumerWidget {
  final Track track;

  const EditTrackModal({
    super.key,
    required this.track,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackRepository = ref.watch(trackRepositoryProvider);

    final formKey = useMemoized(() => GlobalKey<FormState>());

    final autoValidate = useState(false);

    final isLoading = useState(false);

    final hasError = useState(false);

    final titleTextController = useTextEditingController(
      text: track.title,
    );

    final albumTextController = useTextEditingController(
      text: track.metadata.album,
    );

    final artists = useState(
      track.metadata.artists.map((artist) => artist.name).toList(),
    );

    final albumArtists = useState(
      track.metadata.albumArtists.map((artist) => artist.name).toList(),
    );

    final trackNumberTextController = useTextEditingController(
      text: track.metadata.trackNumber.toString(),
    );
    final totalTracksTextController = useTextEditingController(
      text: track.metadata.totalTracks.toString(),
    );
    final discNumberTextController = useTextEditingController(
      text: track.metadata.discNumber.toString(),
    );
    final totalDiscsTextController = useTextEditingController(
      text: track.metadata.totalDiscs.toString(),
    );
    final dateTextController = useTextEditingController(
      text: track.metadata.date,
    );
    final yearTextController = useTextEditingController(
      text: track.metadata.year.toString(),
    );

    final genres = useState([...track.metadata.genres]);

    final acoustIdTextController = useTextEditingController(
      text: track.metadata.acoustId,
    );
    final musicBrainzReleaseIdTextController = useTextEditingController(
      text: track.metadata.musicBrainzReleaseId,
    );
    final musicBrainzTrackIdTextController = useTextEditingController(
      text: track.metadata.musicBrainzTrackId,
    );
    final musicBrainzRecordingIdTextController = useTextEditingController(
      text: track.metadata.musicBrainzRecordingId,
    );
    final composerTextController = useTextEditingController(
      text: track.metadata.composer,
    );
    final commentTextController = useTextEditingController(
      text: track.metadata.comment,
    );

    final lyricsTextController = useTextEditingController(
      text: track.metadata.lyrics,
    );

    final dateAdded = useState(track.dateAdded);

    return IntrinsicHeight(
      child: Stack(
        children: [
          AppModal(
            preventUserClose: true,
            title: Text("Edit \"${track.title}\""),
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextFormField(
                        labelText: "Title",
                        controller: titleTextController,
                        autovalidateMode: autoValidate.value
                            ? AutovalidateMode.always
                            : AutovalidateMode.disabled,
                        validator: FormBuilderValidators.compose(
                          [
                            FormBuilderValidators.required(
                              errorText: "Title should not be empty.",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppTextFormField(
                        labelText: "Album",
                        controller: albumTextController,
                      ),
                      const Divider(
                        height: 24,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Text(
                                  "Track Artists",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 20,
                                    letterSpacing: 20 * 0.04,
                                  ),
                                ),
                                AppIconButton(
                                  icon: const AdwaitaIcon(
                                    AdwaitaIcons.list_add,
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  iconSize: 20,
                                  onPressed: () {
                                    artists.value = [...artists.value, ""];
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                const Text(
                                  "Album Artists",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 20,
                                    letterSpacing: 20 * 0.04,
                                  ),
                                ),
                                AppIconButton(
                                  icon: const AdwaitaIcon(
                                    AdwaitaIcons.list_add,
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  iconSize: 20,
                                  onPressed: () {
                                    albumArtists.value = [
                                      ...albumArtists.value,
                                      ""
                                    ];
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (artists.value.isNotEmpty || artists.value.isNotEmpty)
                        const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: artists.value.indexed.expand(
                                (entry) sync* {
                                  yield AppValueTextField(
                                    labelText: "Track Artist",
                                    value: entry.$2,
                                    suffixIcon: const AdwaitaIcon(
                                      size: 20,
                                      AdwaitaIcons.list_remove,
                                    ),
                                    suffixIconOnPressed: () {
                                      artists.value = [
                                        ...artists.value..removeAt(entry.$1)
                                      ];
                                    },
                                    onChanged: (value) {
                                      artists.value = [
                                        ...artists.value.sublist(0, entry.$1),
                                        value,
                                        ...artists.value.sublist(entry.$1 + 1),
                                      ];
                                    },
                                    autovalidateMode: autoValidate.value
                                        ? AutovalidateMode.always
                                        : AutovalidateMode.disabled,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText:
                                              "Track artist should not be empty.",
                                        ),
                                      ],
                                    ),
                                  );
                                  if (entry.$1 < artists.value.length - 1) {
                                    yield const SizedBox(height: 8);
                                  }
                                },
                              ).toList(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: albumArtists.value.indexed.expand(
                                (entry) sync* {
                                  yield AppValueTextField(
                                    labelText: "Album Artist",
                                    value: entry.$2,
                                    suffixIcon: const AdwaitaIcon(
                                      size: 20,
                                      AdwaitaIcons.list_remove,
                                    ),
                                    suffixIconOnPressed: () {
                                      albumArtists.value = [
                                        ...albumArtists.value
                                          ..removeAt(entry.$1)
                                      ];
                                    },
                                    onChanged: (value) {
                                      albumArtists.value = [
                                        ...albumArtists.value
                                            .sublist(0, entry.$1),
                                        value,
                                        ...albumArtists.value
                                            .sublist(entry.$1 + 1),
                                      ];
                                    },
                                    autovalidateMode: autoValidate.value
                                        ? AutovalidateMode.always
                                        : AutovalidateMode.disabled,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText:
                                              "Album artist not be empty.",
                                        ),
                                      ],
                                    ),
                                  );
                                  if (entry.$1 <
                                      albumArtists.value.length - 1) {
                                    yield const SizedBox(height: 8);
                                  }
                                },
                              ).toList(),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 24,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextFormField(
                              labelText: "Track Number",
                              controller: trackNumberTextController,
                              autovalidateMode: autoValidate.value
                                  ? AutovalidateMode.always
                                  : AutovalidateMode.disabled,
                              validator: FormBuilderValidators.compose(
                                [
                                  FormBuilderValidators.integer(
                                    errorText:
                                        "Track number should be an integer.",
                                  ),
                                  FormBuilderValidators.min(
                                    0,
                                    errorText:
                                        "Track number should be zero or greater.",
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextFormField(
                              labelText: "Total Tracks",
                              controller: totalTracksTextController,
                              autovalidateMode: autoValidate.value
                                  ? AutovalidateMode.always
                                  : AutovalidateMode.disabled,
                              validator: FormBuilderValidators.compose(
                                [
                                  FormBuilderValidators.integer(
                                    errorText:
                                        "Total tracks should be an integer.",
                                  ),
                                  FormBuilderValidators.min(
                                    0,
                                    errorText:
                                        "Total tracks should be zero or greater.",
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextFormField(
                              labelText: "Track Disc",
                              controller: discNumberTextController,
                              autovalidateMode: autoValidate.value
                                  ? AutovalidateMode.always
                                  : AutovalidateMode.disabled,
                              validator: FormBuilderValidators.compose(
                                [
                                  FormBuilderValidators.integer(
                                    errorText:
                                        "Track disc should be an integer.",
                                  ),
                                  FormBuilderValidators.min(
                                    0,
                                    errorText:
                                        "Track disc should be zero or greater.",
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextFormField(
                              labelText: "Total Disc",
                              controller: totalDiscsTextController,
                              autovalidateMode: autoValidate.value
                                  ? AutovalidateMode.always
                                  : AutovalidateMode.disabled,
                              validator: FormBuilderValidators.compose(
                                [
                                  FormBuilderValidators.integer(
                                    errorText:
                                        "Total disc should be an integer.",
                                  ),
                                  FormBuilderValidators.min(
                                    0,
                                    errorText:
                                        "Total disc should be zero or greater.",
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 24,
                      ),
                      AppTextFormField(
                        labelText: "Date",
                        controller: dateTextController,
                      ),
                      const SizedBox(height: 8),
                      AppTextFormField(
                        labelText: "Year",
                        controller: yearTextController,
                        autovalidateMode: autoValidate.value
                            ? AutovalidateMode.always
                            : AutovalidateMode.disabled,
                        validator: FormBuilderValidators.compose(
                          [
                            FormBuilderValidators.integer(
                              errorText: "Year should be an integer.",
                            ),
                            FormBuilderValidators.min(
                              -1,
                              errorText: "Year should be -1 or greater.",
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 24,
                      ),
                      Row(
                        children: [
                          const Text(
                            "Genres",
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 20,
                              letterSpacing: 20 * 0.04,
                            ),
                          ),
                          AppIconButton(
                            icon: const AdwaitaIcon(
                              AdwaitaIcons.list_add,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            iconSize: 20,
                            onPressed: () {
                              genres.value = [...genres.value, ""];
                            },
                          ),
                        ],
                      ),
                      if (genres.value.isNotEmpty) const SizedBox(height: 8),
                      Column(
                        children: genres.value.indexed.expand((entry) sync* {
                          yield AppValueTextField(
                            labelText: "Genre",
                            value: entry.$2,
                            suffixIcon: const AdwaitaIcon(
                              size: 20,
                              AdwaitaIcons.list_remove,
                            ),
                            suffixIconOnPressed: () {
                              genres.value = [
                                ...genres.value..removeAt(entry.$1)
                              ];
                            },
                            onChanged: (value) {
                              genres.value = [
                                ...genres.value.sublist(0, entry.$1),
                                value,
                                ...genres.value.sublist(entry.$1 + 1),
                              ];
                            },
                            autovalidateMode: autoValidate.value
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                            validator: FormBuilderValidators.compose(
                              [
                                FormBuilderValidators.required(
                                  errorText: "Genre should not be empty.",
                                ),
                              ],
                            ),
                          );
                          if (entry.$1 < genres.value.length - 1) {
                            yield const SizedBox(height: 8);
                          }
                        }).toList(),
                      ),
                      const Divider(
                        height: 24,
                      ),
                      AppTextFormField(
                        labelText: "AcoustId",
                        controller: acoustIdTextController,
                      ),
                      const SizedBox(height: 8),
                      AppTextFormField(
                        labelText: "MusicBrainz Release Id",
                        controller: musicBrainzReleaseIdTextController,
                      ),
                      const SizedBox(height: 8),
                      AppTextFormField(
                        labelText: "MusicBrainz Track Id",
                        controller: musicBrainzTrackIdTextController,
                      ),
                      const SizedBox(height: 8),
                      AppTextFormField(
                        labelText: "MusicBrainz Recording Id",
                        controller: musicBrainzRecordingIdTextController,
                      ),
                      const Divider(
                        height: 24,
                      ),
                      AppTextFormField(
                        labelText: "Composer",
                        controller: composerTextController,
                      ),
                      const SizedBox(height: 8),
                      AppTextFormField(
                        labelText: "Comment",
                        controller: commentTextController,
                      ),
                      const Divider(
                        height: 24,
                      ),
                      AppDatetimeFormField(
                        labelText: "Date Added",
                        formatter: DateFormat('yyyy-MM-dd HH:mm'),
                        value: dateAdded.value,
                        onChanged: (value) {
                          dateAdded.value = value;
                        },
                      ),
                      const Divider(
                        height: 24,
                      ),
                      ExpansionTile(
                        shape: const Border(),
                        tilePadding: const EdgeInsets.all(0),
                        title: const Text(
                          "Lyrics",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 20,
                            letterSpacing: 20 * 0.04,
                            color: Colors.white,
                          ),
                        ),
                        children: [
                          AppTextFormField(
                            labelText: "Lyrics",
                            controller: lyricsTextController,
                            maxLines: null,
                          ),
                        ],
                      ),
                      const Divider(
                        height: 24,
                      ),
                      const Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: "Change Audio",
                              type: AppButtonType.secondary,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: AppButton(
                              text: "Change Cover",
                              type: AppButtonType.secondary,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: AppButton(
                              text: "Scan Metadata",
                              type: AppButtonType.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (hasError.value)
                        const AppErrorBox(
                          title: "Error",
                          message: "Something went wrong",
                        ),
                      if (hasError.value) const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: "Cancel",
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
                                  trackRepository.saveTrack(
                                    track.copyWith(
                                      title: titleTextController.text,
                                      metadata: track.metadata.copyWith(
                                        album: albumTextController.text,
                                        artists: artists.value
                                            .map((artist) => MinimalArtist(
                                                id: artist, name: artist))
                                            .toList(),
                                        albumArtists: albumArtists.value
                                            .map((artist) => MinimalArtist(
                                                id: artist, name: artist))
                                            .toList(),
                                        trackNumber: int.parse(
                                          trackNumberTextController.text,
                                        ),
                                        totalTracks: int.parse(
                                          totalTracksTextController.text,
                                        ),
                                        discNumber: int.parse(
                                          discNumberTextController.text,
                                        ),
                                        totalDiscs: int.parse(
                                          totalDiscsTextController.text,
                                        ),
                                        date: dateTextController.text,
                                        year: int.parse(
                                          yearTextController.text,
                                        ),
                                        genres: genres.value,
                                        acoustId: acoustIdTextController.text,
                                        musicBrainzReleaseId:
                                            acoustIdTextController.text,
                                        musicBrainzTrackId:
                                            musicBrainzTrackIdTextController
                                                .text,
                                        musicBrainzRecordingId:
                                            musicBrainzRecordingIdTextController
                                                .text,
                                        comment: commentTextController.text,
                                        lyrics: lyricsTextController.text,
                                      ),
                                      dateAdded: dateAdded.value,
                                    ),
                                  );

                                  ref.invalidate(trackByIdProvider(track.id));

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
                          ),
                        ],
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
}
