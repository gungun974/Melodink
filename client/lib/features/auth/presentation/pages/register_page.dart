import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/core/widgets/app_error_box.dart';
import 'package:melodink_client/core/widgets/app_page_loader.dart';
import 'package:melodink_client/core/widgets/form/app_password_form_field.dart';
import 'package:melodink_client/core/widgets/form/app_text_form_field.dart';
import 'package:melodink_client/core/widgets/gradient_background.dart';
import 'package:melodink_client/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:melodink_client/features/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:melodink_client/generated/i18n/translations.g.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(
        authViewModel: context.read(),
        settingsViewModel: context.read(),
      ),
      child: Stack(
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
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                t.actions.createAccount,
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
              child: Consumer<RegisterViewModel>(
                builder: (context, viewModel, _) {
                  return Form(
                    key: viewModel.formKey,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 1200.0),
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppTextFormField(
                                  controller: viewModel.nameTextController,
                                  labelText: t.general.username,
                                  keyboardType: TextInputType.text,
                                  autovalidateMode: viewModel.autoValidate
                                      ? AutovalidateMode.always
                                      : AutovalidateMode.disabled,
                                  validator: FormBuilderValidators.required(
                                    errorText: t.validators
                                        .fieldShouldNotBeEmpty(
                                          field: t.general.username,
                                        ),
                                  ),
                                  autofillHints: const [
                                    AutofillHints.newUsername,
                                  ],
                                ),
                                const SizedBox(height: 12.0),
                                AppTextFormField(
                                  controller: viewModel.emailTextController,
                                  labelText: t.general.emailAddress,
                                  keyboardType: TextInputType.emailAddress,
                                  autovalidateMode: viewModel.autoValidate
                                      ? AutovalidateMode.always
                                      : AutovalidateMode.disabled,
                                  validator: FormBuilderValidators.compose([
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
                                  ]),
                                  autofillHints: const [AutofillHints.email],
                                ),
                                const SizedBox(height: 12.0),
                                AppPasswordFormField(
                                  controller: viewModel.passwordTextController,
                                  labelText: t.general.password,
                                  autovalidateMode: viewModel.autoValidate
                                      ? AutovalidateMode.always
                                      : AutovalidateMode.disabled,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(
                                      errorText: t.validators
                                          .fieldShouldNotBeEmpty(
                                            field: t.general.password,
                                          ),
                                    ),
                                    FormBuilderValidators.minLength(
                                      8,
                                      errorText: t.validators
                                          .fieldMustBeAtLeast(
                                            field: t.general.password,
                                            n: 8,
                                          ),
                                    ),
                                    FormBuilderValidators.maxLength(
                                      32,
                                      errorText: t.validators
                                          .fieldMustNotExceed(
                                            field: t.general.password,
                                            n: 32,
                                          ),
                                    ),
                                  ]),
                                  autofillHints: const [
                                    AutofillHints.newUsername,
                                  ],
                                ),
                                const SizedBox(height: 12.0),
                                AppPasswordFormField(
                                  labelText: t.general.confirmPassword,
                                  autovalidateMode: viewModel.autoValidate
                                      ? AutovalidateMode.always
                                      : AutovalidateMode.disabled,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(
                                      errorText: t.validators
                                          .fieldShouldNotBeEmpty(
                                            field: t.general.confirmPassword,
                                          ),
                                    ),
                                    (value) {
                                      if (value !=
                                          viewModel
                                              .passwordTextController
                                              .text) {
                                        return t.validators.passwordDontMatch;
                                      }
                                      return null;
                                    },
                                  ]),
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                ),
                                const SizedBox(height: 12.0),
                                AppButton(
                                  text: t.general.create,
                                  type: AppButtonType.primary,
                                  onPressed: () => viewModel.register(context),
                                ),
                                Consumer<AuthViewModel>(
                                  builder: (context, viewModel, _) {
                                    final auth = viewModel.state;

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
                  );
                },
              ),
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
