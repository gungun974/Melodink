import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:melodink_client/core/api/api.dart';
import 'package:mutex/mutex.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class NetworkInfo extends ChangeNotifier {
  bool _isServerRecheable = true;
  bool _forceOffline = false;

  final SharedPreferencesAsync _asyncPrefs = SharedPreferencesAsync();

  NetworkInfo._privateConstructor();

  static final NetworkInfo _instance = NetworkInfo._privateConstructor();

  factory NetworkInfo() {
    return _instance;
  }

  final StreamController<bool> _forceOfflineStreamController =
      StreamController<bool>.broadcast();

  Stream<bool> get forceOfflineStream {
    return _forceOfflineStreamController.stream;
  }

  Future<void> setForceOffline(bool force) async {
    await _asyncPrefs.setBool("forceOfflineMode", force);
    _forceOffline = force;
    _forceOfflineStreamController.add(force);
    _streamController.add(isServerRecheable());
    notifyListeners();
  }

  bool getForceOffline() {
    return _forceOffline;
  }

  bool isServerRecheable() {
    if (_forceOffline) {
      return false;
    }
    return _isServerRecheable;
  }

  Future<void> setSavedForceOffline() async {
    _forceOffline = await _asyncPrefs.getBool("forceOfflineMode") ?? false;
    _forceOfflineStreamController.add(_forceOffline);
    notifyListeners();
  }

  final _connectivity = Connectivity();

  final StreamController<bool> _streamController =
      StreamController<bool>.broadcast();

  Stream<bool> get stream {
    return _streamController.stream;
  }

  final mutex = Mutex();

  void startCheckServerReachable() async {
    return mutex.protect(() async {
      while (true) {
        if (_isServerRecheable) {
          return;
        }

        if (_forceOffline) {
        } else if (AppApi().hasServerUrl()) {
          final connectivityResult = await (_connectivity.checkConnectivity());

          if (connectivityResult.contains(ConnectivityResult.none)) {
            _isServerRecheable = false;

            await Future.delayed(const Duration(seconds: 2));

            continue;
          }

          try {
            final response = await AppApi().dio.get(
              "/health",
              options: Options(
                headers: {},
                receiveTimeout: const Duration(seconds: 3),
              ),
            );

            _isServerRecheable = response.statusCode == 200;
            _streamController.add(_isServerRecheable);
            notifyListeners();
          } catch (_) {
            _isServerRecheable = false;
            _streamController.add(_isServerRecheable);
            notifyListeners();
          }
        } else {
          _isServerRecheable = false;
          _streamController.add(_isServerRecheable);
          notifyListeners();
        }

        await Future.delayed(const Duration(seconds: 1));
      }
    });
  }

  void reportNetworkUnrechable() {
    _isServerRecheable = false;
    startCheckServerReachable();
  }
}
