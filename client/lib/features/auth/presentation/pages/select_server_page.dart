import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_error_box.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/auth/domain/providers/server_setup_provider.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class SelectServerPage extends HookConsumerWidget {
  const SelectServerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverSetup = ref.watch(serverSetupNotifierProvider);

    final formKey = useMemoized(() => GlobalKey<FormState>());

    final autoValidate = useState(false);

    String hostTextControllerInitialValue = "";

    if (serverSetup is ServerSetupConfigured) {
      hostTextControllerInitialValue = serverSetup.serverUrl;
    }

    final hostTextController = useTextEditingController(
      text: hostTextControllerInitialValue,
    );

    return Stack(
      children: [
        const GradientBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: GoRouter.of(context).canPop()
              ? AppBar(
                  leading: IconButton(
                    icon: SvgPicture.asset(
                      "assets/icons/arrow-left.svg",
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    t.actions.changeServer,
                    style: TextStyle(
                      fontSize: 20,
                      letterSpacing: 20 * 0.03,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  centerTitle: true,
                  backgroundColor: const Color.fromRGBO(0, 0, 0, 0.08),
                  shadowColor: Colors.transparent,
                )
              : null,
          body: SafeArea(
            child: Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  bottom: 24.0,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!GoRouter.of(context).canPop())
                          const Padding(
                            padding: EdgeInsets.only(top: 16.0),
                            child: Image(
                              image: AssetImage("assets/melodink_fulllogo.png"),
                            ),
                          ),
                        const SizedBox(height: 16.0),
                        Text(
                          t.general.connectToServer,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24,
                            letterSpacing: 24 * 0.03,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        AppTextFormField(
                          controller: hostTextController,
                          labelText: t.general.host,
                          keyboardType: TextInputType.url,
                          autovalidateMode: autoValidate.value
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          validator: FormBuilderValidators.compose(
                            [
                              FormBuilderValidators.required(
                                errorText: t.validators.fieldShouldBeFilled(
                                  field: t.general.host,
                                ),
                              ),
                              FormBuilderValidators.url(
                                protocols: ["http", "https"],
                                errorText: t.validators.fieldShouldBeAValidUrl(
                                  field: t.general.host,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        AppButton(
                          text: t.actions.connect,
                          type: AppButtonType.primary,
                          onPressed: () async {
                            final currentState = formKey.currentState;
                            if (currentState == null) {
                              return;
                            }

                            if (!currentState.validate()) {
                              autoValidate.value = true;
                              return;
                            }

                            final serverSetupNotifier =
                                ref.read(serverSetupNotifierProvider.notifier);

                            final success = await serverSetupNotifier
                                .checkAndSetServerUrl(hostTextController.text);

                            if (!success) {
                              return;
                            }

                            if (!context.mounted) {
                              return;
                            }

                            GoRouter.of(context).go("/");
                          },
                        ),
                        if (serverSetup is ServerSetupError)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: AppErrorBox(
                              title: serverSetup.title,
                              message: serverSetup.message,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (serverSetup is ServerSetupLoading) const AppPageLoader(),
      ],
    );
  }
}
