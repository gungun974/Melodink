import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_error_box.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/form/app_password_form_field.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:melodink_client/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginViewModel(authViewModel: context.read()),
      child: Stack(
        children: [
          const GradientBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: LayoutBuilder(
              builder: (context, constraints) {
                final screenSize = MediaQuery.of(context).size;

                final availableHeight =
                    screenSize.height -
                    MediaQuery.of(context).viewInsets.bottom -
                    MediaQuery.of(context).viewPadding.top -
                    MediaQuery.of(context).viewPadding.bottom;

                return Form(
                  key: context.read<LoginViewModel>().formKey,
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: availableHeight),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 24.0,
                              right: 24.0,
                              bottom: 16.0,
                            ),
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 1200.0,
                                ),
                                child: AutofillGroup(
                                  child: Consumer<LoginViewModel>(
                                    builder: (context, viewModel, _) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const Spacer(),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 16.0,
                                            ),
                                            child: Image(
                                              image: AssetImage(
                                                "assets/melodink_fulllogo.png",
                                              ),
                                            ),
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
                                            controller:
                                                viewModel.emailTextController,
                                            labelText: t.general.emailAddress,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            autovalidateMode:
                                                viewModel.autoValidate
                                                ? AutovalidateMode.always
                                                : AutovalidateMode.disabled,
                                            validator:
                                                FormBuilderValidators.compose([
                                                  FormBuilderValidators.required(
                                                    errorText: t.validators
                                                        .fieldShouldNotBeEmpty(
                                                          field:
                                                              t.general.email,
                                                        ),
                                                  ),
                                                  FormBuilderValidators.email(
                                                    errorText: t.validators
                                                        .fieldShouldBeValidEmail(
                                                          field:
                                                              t.general.email,
                                                        ),
                                                  ),
                                                ]),
                                            autofillHints: const [
                                              AutofillHints.email,
                                            ],
                                          ),
                                          const SizedBox(height: 12.0),
                                          AppPasswordFormField(
                                            controller: viewModel
                                                .passwordTextController,
                                            labelText: t.general.password,
                                            autovalidateMode:
                                                viewModel.autoValidate
                                                ? AutovalidateMode.always
                                                : AutovalidateMode.disabled,
                                            validator:
                                                FormBuilderValidators.required(
                                                  errorText: t.validators
                                                      .fieldShouldNotBeEmpty(
                                                        field:
                                                            t.general.password,
                                                      ),
                                                ),
                                            autofillHints: const [
                                              AutofillHints.password,
                                            ],
                                          ),
                                          const SizedBox(height: 12.0),
                                          AppButton(
                                            text: t.actions.login,
                                            type: AppButtonType.primary,
                                            onPressed: () =>
                                                viewModel.login(context),
                                          ),
                                          Consumer<AuthViewModel>(
                                            builder: (context, viewModel, _) {
                                              final auth = viewModel.state;

                                              if (auth == null ||
                                                  auth is! AuthError) {
                                                return const SizedBox.shrink();
                                              }

                                              if (auth.page !=
                                                  AuthErrorPage.login) {
                                                return const SizedBox.shrink();
                                              }

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 12.0,
                                                ),
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
                                              GoRouter.of(
                                                context,
                                              ).push("/auth/register");
                                            },
                                          ),
                                          const SizedBox(height: 12.0),
                                          AppButton(
                                            text: t.actions.changeServer,
                                            type: AppButtonType.secondary,
                                            onPressed: () {
                                              GoRouter.of(
                                                context,
                                              ).push("/auth/serverSetup");
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Selector<AuthViewModel, bool>(
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
}
