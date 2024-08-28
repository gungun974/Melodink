import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

class RegisterPage extends HookConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final autoValidate = useState(false);

    final nameTextController = useTextEditingController();

    final emailTextController = useTextEditingController();

    final passwordTextController = useTextEditingController();

    return Stack(
      children: [
        const GradientBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              icon: SvgPicture.asset(
                "assets/icons/arrow-left.svg",
                width: 24,
                height: 24,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              "Create Account",
              style: TextStyle(
                fontSize: 20,
                letterSpacing: 20 * 0.03,
                fontWeight: FontWeight.w400,
              ),
            ),
            centerTitle: true,
            backgroundColor: const Color.fromRGBO(0, 0, 0, 0.08),
            shadowColor: Colors.transparent,
          ),
          body: SafeArea(
            child: Form(
              key: formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextFormField(
                          controller: nameTextController,
                          labelText: "Username",
                          keyboardType: TextInputType.text,
                          autovalidateMode: autoValidate.value
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          validator: FormBuilderValidators.required(
                            errorText:
                                "The username field should not be empty.",
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        AppTextFormField(
                          controller: emailTextController,
                          labelText: "Email Address",
                          keyboardType: TextInputType.emailAddress,
                          autovalidateMode: autoValidate.value
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          validator: FormBuilderValidators.compose(
                            [
                              FormBuilderValidators.required(
                                errorText:
                                    "The email field should not be empty.",
                              ),
                              FormBuilderValidators.email(
                                errorText:
                                    "The email field should contain a valid email address.",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        AppPasswordFormField(
                          controller: passwordTextController,
                          labelText: "Password",
                          autovalidateMode: autoValidate.value
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          validator: FormBuilderValidators.compose(
                            [
                              FormBuilderValidators.required(
                                errorText:
                                    "The password field should not be empty",
                              ),
                              FormBuilderValidators.minLength(8,
                                  errorText:
                                      "Password must be at least 8 characters long"),
                              FormBuilderValidators.maxLength(32,
                                  errorText:
                                      "Password must not exceed 32 characters"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        AppPasswordFormField(
                          labelText: "Confirm Password",
                          autovalidateMode: autoValidate.value
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          validator: FormBuilderValidators.compose(
                            [
                              FormBuilderValidators.required(
                                errorText:
                                    "The confirm password field should not be empty",
                              ),
                              (value) {
                                if (value != passwordTextController.text) {
                                  return 'Passwords do not match second one';
                                }
                                return null;
                              },
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        AppButton(
                          text: "Create",
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

                            final authNotifier =
                                ref.read(authNotifierProvider.notifier);

                            final success = await authNotifier.register(
                              nameTextController.text,
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
                            final asyncAuth = ref.watch(authNotifierProvider);

                            final auth = asyncAuth.valueOrNull;

                            if (auth == null || auth is! AuthError) {
                              return const SizedBox.shrink();
                            }

                            if (auth.page != AuthErrorPage.register) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: AppErrorBox(
                                title: auth.title,
                                message: auth.message,
                              ),
                            );
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
