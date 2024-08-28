import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/features/auth/data/repository/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_setup_provider.g.dart';

abstract class ServerSetupState extends Equatable {
  const ServerSetupState();

  @override
  List<Object?> get props => [];
}

class ServerSetupUnconfigured extends ServerSetupState {}

class ServerSetupLoading extends ServerSetupState {}

class ServerSetupConfigured extends ServerSetupState {
  final String serverUrl;

  const ServerSetupConfigured({
    required this.serverUrl,
  });

  @override
  List<Object> get props => [
        serverUrl,
      ];
}

class ServerSetupError extends ServerSetupState {
  final String? title;
  final String message;

  const ServerSetupError({
    this.title,
    required this.message,
  });

  @override
  List<Object?> get props => [title, message];
}

@riverpod
class ServerSetupNotifier extends _$ServerSetupNotifier {
  late AuthRepository authRepository;

  @override
  ServerSetupState build() {
    authRepository = ref.read(authRepositoryProvider);

    final serverUrl = AppApi().getServerUrl().trim();

    if (serverUrl.isEmpty) {
      return ServerSetupUnconfigured();
    }

    return ServerSetupConfigured(
      serverUrl: serverUrl,
    );
  }

  Future<bool> checkAndSetServerUrl(String serverUrl) async {
    state = ServerSetupLoading();

    try {
      final savedServerUrl = await authRepository.checkAndSetServerUrl(
        serverUrl,
      );

      state = ServerSetupConfigured(serverUrl: savedServerUrl);

      return true;
    } on AuthServerNotFoundException {
      state = const ServerSetupError(
        title: "Error",
        message: "The server was not found",
      );
    } on AuthServerNotCompatibleException {
      state = const ServerSetupError(
        title: "Error",
        message: "This server is not compatible",
      );
    } catch (e) {
      state = const ServerSetupError(message: "An error was not expected");
    }

    return false;
  }
}

@riverpod
bool isServerConfigured(IsServerConfiguredRef ref) {
  final serverSetup = ref.watch(serverSetupNotifierProvider);

  return serverSetup is ServerSetupConfigured;
}
