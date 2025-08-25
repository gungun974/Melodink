import 'package:flutter/widgets.dart';
import 'package:melodink_client/core/routes/router.dart';
import 'package:melodink_client/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:melodink_client/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:provider/provider.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthViewModel authViewModel;
  final SettingsViewModel settingsViewModel;

  LoginViewModel({
    required this.authViewModel,
    required this.settingsViewModel,
  });

  final formKey = GlobalKey<FormState>();

  bool autoValidate = false;

  final emailTextController = TextEditingController();

  final passwordTextController = TextEditingController();

  @override
  void dispose() {
    emailTextController.dispose();
    passwordTextController.dispose();

    super.dispose();
  }

  Future<void> login(BuildContext context) async {
    final currentState = formKey.currentState;
    if (currentState == null) {
      return;
    }

    if (!currentState.validate()) {
      autoValidate = true;
      notifyListeners();
      return;
    }

    final success = await authViewModel.login(
      emailTextController.text,
      passwordTextController.text,
    );

    if (!success) {
      return;
    }

    settingsViewModel.loadSettings();

    if (!context.mounted) {
      return;
    }

    context.read<AppRouter>().go("/");
  }
}
