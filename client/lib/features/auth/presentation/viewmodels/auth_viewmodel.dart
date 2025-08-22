import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/database/database.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/features/auth/data/repository/auth_repository.dart';
import 'package:melodink_client/features/auth/domain/entities/user.dart';
import 'package:melodink_client/features/player/domain/audio/audio_controller.dart';

enum AuthStatus { unauthenticated, authenticated }

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthLoaded extends AuthState {
  final AuthStatus status;
  final User? user;

  const AuthLoaded({required this.status, this.user});

  @override
  List<Object?> get props => [status, user];
}

enum AuthErrorPage { login, register }

class AuthError extends AuthState {
  final String? title;
  final String message;

  final AuthErrorPage page;

  const AuthError({this.title, required this.message, required this.page});

  @override
  List<Object?> get props => [title, message];
}

class AuthViewModel extends ChangeNotifier {
  final AudioController audioController;
  final AuthRepository authRepository;

  AuthViewModel({required this.audioController, required this.authRepository}) {
    AppApi().dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
          if (error.response?.statusCode == 401) {
            final currentState = state;

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

    _future = _init();
  }

  late final Future<void> _future;

  Future<void> _init() async {
    try {
      final user = await authRepository.getCurrentUser();
      if (user == null) {
        state = const AuthLoaded(status: AuthStatus.unauthenticated);
      } else {
        state = AuthLoaded(status: AuthStatus.authenticated, user: user);
      }
    } catch (_) {
      state = const AuthLoaded(status: AuthStatus.unauthenticated);
    } finally {
      notifyListeners();
    }
  }

  Future<void> waitForLoading() => _future;

  AuthState? state;

  bool get isLoading => state == null;

  Future<bool> login(String email, password) async {
    state = null;
    notifyListeners();

    try {
      final user = await authRepository.login(email, password);

      try {
        await DatabaseService.getDatabase();
      } catch (_) {}

      state = AuthLoaded(status: AuthStatus.authenticated, user: user);
      notifyListeners();

      return true;
    } on AuthServerUnauthorizedException {
      state = const AuthError(
        title: "Invalid login",
        message: "The password or email is wrong",
        page: AuthErrorPage.login,
      );
      notifyListeners();
    } on ServerTimeoutException {
      state = const AuthError(
        message: "Server has timeout",
        page: AuthErrorPage.login,
      );
      notifyListeners();
    } catch (e) {
      state = const AuthError(
        message: "An error was not expected",
        page: AuthErrorPage.login,
      );
      notifyListeners();
    }

    return false;
  }

  Future<bool> register(String name, email, password) async {
    state = null;
    notifyListeners();

    try {
      final user = await authRepository.register(name, email, password);

      state = AuthLoaded(status: AuthStatus.authenticated, user: user);
      notifyListeners();

      return true;
    } on ServerTimeoutException {
      state = const AuthError(
        message: "Server has timeout",
        page: AuthErrorPage.register,
      );
      notifyListeners();
    } catch (e) {
      state = const AuthError(
        message: "An error was not expected",
        page: AuthErrorPage.register,
      );
      notifyListeners();
    }

    return false;
  }

  Future<void> logout() async {
    await audioController.clean();

    await authRepository.logout();

    try {
      await DatabaseService.disconnectDatabase();
    } catch (_) {}

    state = const AuthLoaded(status: AuthStatus.unauthenticated);
    notifyListeners();
  }

  bool getIsUserAuthenticated() {
    try {
      final auth = state;

      if (auth is! AuthLoaded) {
        return false;
      }
      return auth.status == AuthStatus.authenticated;
    } catch (e) {
      return false;
    }
  }

  User? getLoggedUser() {
    try {
      final auth = state;

      if (auth is! AuthLoaded) {
        return null;
      }

      return auth.user;
    } catch (e) {
      return null;
    }
  }
}
