import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/features/auth/data/repository/auth_repository.dart';

abstract class ServerSetupState extends Equatable {
  const ServerSetupState();

  @override
  List<Object?> get props => [];
}

class ServerSetupUnconfigured extends ServerSetupState {}

class ServerSetupLoading extends ServerSetupState {}

class ServerSetupConfigured extends ServerSetupState {
  final String serverUrl;

  const ServerSetupConfigured({required this.serverUrl});

  @override
  List<Object> get props => [serverUrl];
}

class ServerSetupError extends ServerSetupState {
  final String? title;
  final String message;

  const ServerSetupError({this.title, required this.message});

  @override
  List<Object?> get props => [title, message];
}

class ServerSetupViewModel extends ChangeNotifier {
  final AuthRepository authRepository;

  ServerSetupViewModel({required this.authRepository}) {
    final serverUrl = AppApi().getServerUrl().trim();

    if (serverUrl.isEmpty) {
      state = ServerSetupUnconfigured();
      notifyListeners();
      return;
    }

    state = ServerSetupConfigured(serverUrl: serverUrl);
    notifyListeners();
  }

  late ServerSetupState state;

  Future<bool> checkAndSetServerUrl(String serverUrl) async {
    state = ServerSetupLoading();
    notifyListeners();

    try {
      final savedServerUrl = await authRepository.checkAndSetServerUrl(
        serverUrl,
      );

      state = ServerSetupConfigured(serverUrl: savedServerUrl);
      notifyListeners();

      return true;
    } on AuthServerNotFoundException {
      state = const ServerSetupError(
        title: "Error",
        message: "The server was not found",
      );
      notifyListeners();
    } on AuthServerNotCompatibleException {
      state = const ServerSetupError(
        title: "Error",
        message: "This server is not compatible",
      );
      notifyListeners();
    } catch (e) {
      state = const ServerSetupError(message: "An error was not expected");
      notifyListeners();
    }

    return false;
  }

  bool getIsServerConfigured() {
    final serverSetup = state;

    return serverSetup is ServerSetupConfigured;
  }
}
