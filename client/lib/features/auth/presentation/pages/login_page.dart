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
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Form(
              key: formKey,
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Spacer(),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Image(
                                      image: AssetImage(
                                          "assets/melodink_fulllogo.png")),
                                ),
                                const Text(
                                  "Please sign in",
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
                                  validator: FormBuilderValidators.required(
                                    errorText:
                                        "The password field should not be empty",
                                  ),
                                ),
                                const SizedBox(height: 12.0),
                                AppButton(
                                  text: "Connect",
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
                                      padding: const EdgeInsets.only(top: 12.0),
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
                                  text: "Create Account",
                                  type: AppButtonType.secondary,
                                  onPressed: () {
                                    GoRouter.of(context).push("/auth/register");
                                  },
                                ),
                                const SizedBox(height: 12.0),
                                AppButton(
                                  text: "Change Server",
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
                );
              }),
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
