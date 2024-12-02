import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:melodink_client/core/error/exceptions.dart';
import 'package:melodink_client/features/auth/data/models/user_model.dart';
import 'package:melodink_client/features/auth/domain/entities/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthServerNotFoundException implements Exception {}

class AuthServerNotCompatibleException implements Exception {}

class AuthServerUnauthorizedException implements Exception {}

class AuthRepository {
  final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();

  Future<String> checkAndSetServerUrl(String rawServerUrl) async {
    final serverUrl = rawServerUrl.trim().replaceAll(RegExp(r'/+$'), '');

    try {
      final response = await Dio().get("$serverUrl/check");

      if (response.statusCode != 200) {
        throw AuthServerNotFoundException();
      }

      if (response.data != "IamAMelodinkCompatibleServer") {
        throw AuthServerNotCompatibleException();
      }

      await AppApi().setServerUrl("$serverUrl/");

      final uuidResponse = await AppApi().dio.get("/uuid");

      await AppApi().setServerUUID(uuidResponse.data);

      return serverUrl;
    } on DioException catch (e) {
      if (e.response == null) {
        throw AuthServerNotFoundException();
      }
      throw AuthServerNotCompatibleException();
    } catch (e) {
      throw ServerUnknownException();
    }
  }

  Future<User> login(String email, password) async {
    try {
      await AppApi().dio.post(
        "/login",
        data: {
          "email": email.trim(),
          "password": password.trim(),
        },
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode != 401) {
        throw ServerUnknownException();
      }

      throw AuthServerUnauthorizedException();
    } catch (e) {
      throw ServerUnknownException();
    }

    final user = await getCurrentUser();

    if (user == null) {
      throw ServerUnknownException();
    }

    return user;
  }

  Future<User?> getCurrentUser() async {
    final cachedUser = await asyncPrefs.getString("current_user_cache");

    if (cachedUser != null) {
      return UserModel.fromJson(json.decode(cachedUser)).toUser();
    }

    try {
      final response = await AppApi().dio.get("/me");

      final model = UserModel.fromJson(response.data);

      await asyncPrefs.setString(
        "current_user_cache",
        json.encode(
          model.toJson(),
        ),
      );

      return model.toUser();
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      throw ServerUnknownException();
    } catch (e) {
      throw ServerUnknownException();
    }
  }

  static Future<User?> getCachedUser() async {
    final cachedUser =
        await SharedPreferencesAsync().getString("current_user_cache");

    if (cachedUser != null) {
      return UserModel.fromJson(json.decode(cachedUser)).toUser();
    }

    return null;
  }

  Future<User> register(String name, email, password) async {
    try {
      await AppApi().dio.post(
        "/register",
        data: {
          "name": name.trim(),
          "email": email.trim(),
          "password": password.trim(),
        },
      );

      await AppApi().dio.post(
        "/login",
        data: {
          "email": email.trim(),
          "password": password.trim(),
        },
      );
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) {
        throw ServerTimeoutException();
      }

      if (response.statusCode != 401) {
        throw ServerUnknownException();
      }

      throw ServerUnknownException();
    } catch (e) {
      throw ServerUnknownException();
    }

    final user = await getCurrentUser();

    if (user == null) {
      throw ServerUnknownException();
    }

    return user;
  }

  Future<void> logout() async {
    await asyncPrefs.remove("current_user_cache");

    await AppApi().cookieJar.deleteAll();
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository());
