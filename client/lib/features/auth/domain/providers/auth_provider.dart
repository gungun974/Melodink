import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/features/auth/data/repository/auth_repository.dart';
import 'package:melodink_client/features/auth/domain/entities/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

enum AuthStatus {
  unauthenticated,
  authenticated,
}

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthLoaded extends AuthState {
  final AuthStatus status;
  final User? user;

  const AuthLoaded({
    required this.status,
    this.user,
  });

  @override
  List<Object?> get props => [
        status,
        user,
      ];
}

enum AuthErrorPage {
  login,
  register,
}

class AuthError extends AuthState {
  final String? title;
  final String message;

  final AuthErrorPage page;

  const AuthError({
    this.title,
    required this.message,
    required this.page,
  });

  @override
  List<Object?> get props => [title, message];
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  late AuthRepository _authRepository;

  @override
  Future<AuthState> build() async {
    _authRepository = ref.read(authRepositoryProvider);

    AppApi().dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
          if (error.response?.statusCode == 401) {
            final currentState = state.valueOrNull;

            if (currentState is AuthLoaded &&
                currentState.status == AuthStatus.authenticated) {
              logout();
              return;
            }
          }
          return handler.next(error);
        },
      ),
    );

    final user = await _authRepository.getCurrentUser();

    if (user == null) {
      return const AuthLoaded(
        status: AuthStatus.unauthenticated,
      );
    }

    return AuthLoaded(
      status: AuthStatus.authenticated,
      user: user,
    );
  }

  Future<bool> login(String email, password) async {
    state = const AsyncValue.loading();

    try {
      final user = await _authRepository.login(email, password);

      state = AsyncValue.data(AuthLoaded(
        status: AuthStatus.authenticated,
        user: user,
      ));

      return true;
    } on AuthServerUnauthorizedException {
      state = const AsyncValue.data(
        AuthError(
          title: "Invalid login",
          message: "The password or email is wrong",
          page: AuthErrorPage.login,
        ),
      );
    } on ServerTimeoutException {
      state = const AsyncValue.data(
        AuthError(
          message: "Server has timeout",
          page: AuthErrorPage.login,
        ),
      );
    } catch (e) {
      state = const AsyncValue.data(
        AuthError(
          message: "An error was not expected",
          page: AuthErrorPage.login,
        ),
      );
    }

    return false;
  }

  Future<bool> register(String name, email, password) async {
    state = const AsyncValue.loading();

    try {
      final user = await _authRepository.register(name, email, password);

      state = AsyncValue.data(AuthLoaded(
        status: AuthStatus.authenticated,
        user: user,
      ));

      return true;
    } on ServerTimeoutException {
      state = const AsyncValue.data(
        AuthError(
          message: "Server has timeout",
          page: AuthErrorPage.register,
        ),
      );
    } catch (e) {
      state = const AsyncValue.data(
        AuthError(
          message: "An error was not expected",
          page: AuthErrorPage.register,
        ),
      );
    }

    return false;
  }

  Future<void> logout() async {
    await _authRepository.logout();

    state = const AsyncValue.data(AuthLoaded(
      status: AuthStatus.unauthenticated,
    ));
  }
}

@riverpod
Future<bool> isUserAuthenticated(IsUserAuthenticatedRef ref) async {
  try {
    final auth = await ref.watch(authNotifierProvider.future);

    if (auth is! AuthLoaded) {
      return false;
    }
    return auth.status == AuthStatus.authenticated;
  } catch (e) {
    return false;
  }
}

@riverpod
Future<User?> loggedUser(LoggedUserRef ref) async {
  try {
    final auth = await ref.watch(authNotifierProvider.future);

    if (auth is! AuthLoaded) {
      return null;
    }

    return auth.user;
  } catch (e) {
    return null;
  }
}
