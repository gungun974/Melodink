import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_error_box.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/form/app_password_form_field.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/auth/domain/providers/auth_provider.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final autoValidate = useState(false);

    final emailTextController = useTextEditingController();

    final passwordTextController = useTextEditingController();

    return Stack(
      children: [
        const GradientBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Form(
            key: formKey,
            child: LayoutBuilder(builder: (context, constraints) {
              final screenSize = MediaQuery.of(context).size;

              final availableHeight = screenSize.height -
                  MediaQuery.of(context).viewInsets.bottom -
                  MediaQuery.of(context).viewPadding.top -
                  MediaQuery.of(context).viewPadding.bottom;

              return SafeArea(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: availableHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 24.0,
                          right: 24.0,
                          bottom: 16.0,
                        ),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 1200.0),
                            child: AutofillGroup(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Spacer(),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16.0),
                                    child: Image(
                                        image: AssetImage(
                                            "assets/melodink_fulllogo.png")),
                                  ),
                                  Text(
                                    t.general.signIn,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 24,
                                      letterSpacing: 24 * 0.03,
                                    ),
                                  ),
                                  const SizedBox(height: 12.0),
                                  AppTextFormField(
                                    controller: emailTextController,
                                    labelText: t.general.emailAddress,
                                    keyboardType: TextInputType.emailAddress,
                                    autovalidateMode: autoValidate.value
                                        ? AutovalidateMode.always
                                        : AutovalidateMode.disabled,
                                    validator: FormBuilderValidators.compose(
                                      [
                                        FormBuilderValidators.required(
                                          errorText: t.validators
                                              .fieldShouldNotBeEmpty(
                                            field: t.general.email,
                                          ),
                                        ),
                                        FormBuilderValidators.email(
                                          errorText: t.validators
                                              .fieldShouldBeValidEmail(
                                            field: t.general.email,
                                          ),
                                        ),
                                      ],
                                    ),
                                    autofillHints: const [AutofillHints.email],
                                  ),
                                  const SizedBox(height: 12.0),
                                  AppPasswordFormField(
                                    controller: passwordTextController,
                                    labelText: t.general.password,
                                    autovalidateMode: autoValidate.value
                                        ? AutovalidateMode.always
                                        : AutovalidateMode.disabled,
                                    validator: FormBuilderValidators.required(
                                      errorText:
                                          t.validators.fieldShouldNotBeEmpty(
                                        field: t.general.password,
                                      ),
                                    ),
                                    autofillHints: const [
                                      AutofillHints.password
                                    ],
                                  ),
                                  const SizedBox(height: 12.0),
                                  AppButton(
                                    text: t.actions.login,
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

                                      final authNotifier = ref
                                          .read(authNotifierProvider.notifier);

                                      final success = await authNotifier.login(
                                        emailTextController.text,
                                        passwordTextController.text,
                                      );

                                      if (!success) {
                                        return;
                                      }

                                      if (!context.mounted) {
                                        return;
                                      }

                                      GoRouter.of(context).go("/");
                                    },
                                  ),
                                  Consumer(
                                    builder: (
                                      BuildContext context,
                                      WidgetRef ref,
                                      Widget? child,
                                    ) {
                                      final asyncAuth =
                                          ref.watch(authNotifierProvider);

                                      final auth = asyncAuth.valueOrNull;

                                      if (auth == null || auth is! AuthError) {
                                        return const SizedBox.shrink();
                                      }

                                      if (auth.page != AuthErrorPage.login) {
                                        return const SizedBox.shrink();
                                      }

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 12.0),
                                        child: AppErrorBox(
                                          title: auth.title,
                                          message: auth.message,
                                        ),
                                      );
                                    },
                                  ),
                                  const Spacer(),
                                  const SizedBox(height: 24.0),
                                  AppButton(
                                    text: t.actions.createAccount,
                                    type: AppButtonType.secondary,
                                    onPressed: () {
                                      GoRouter.of(context)
                                          .push("/auth/register");
                                    },
                                  ),
                                  const SizedBox(height: 12.0),
                                  AppButton(
                                    text: t.actions.changeServer,
                                    type: AppButtonType.secondary,
                                    onPressed: () {
                                      GoRouter.of(context)
                                          .push("/auth/serverSetup");
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Consumer(
          builder: (
            BuildContext context,
            WidgetRef ref,
            Widget? child,
          ) {
            final asyncAuth = ref.watch(authNotifierProvider);

            if (!asyncAuth.isLoading) {
              return const SizedBox.shrink();
            }

            return const AppPageLoader();
          },
        ),
      ],
    );
  }
}
