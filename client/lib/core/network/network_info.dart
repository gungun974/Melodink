import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/api/api.dart';

class NetworkInfo {
  bool _isServerRecheable = true;

  bool isServerRecheable() {
    return _isServerRecheable;
  }

  NetworkInfo() {
    checkServerReachable();
  }

  final _connectivity = Connectivity();

  void checkServerReachable() async {
    while (true) {
      if (AppApi().hasServerUrl()) {
        final uri = Uri.parse(AppApi().getServerUrl());

        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          final connectivityResult = await (_connectivity.checkConnectivity());

          if (connectivityResult.contains(ConnectivityResult.none)) {
            _isServerRecheable = false;

            await Future.delayed(const Duration(
              seconds: 2,
            ));

            continue;
          }
        }

        try {
          final response = await AppApi().dio.get(
                "/health",
                options: Options(
                  headers: {},
                ),
              );

          _isServerRecheable = response.statusCode == 200;
        } catch (_) {
          _isServerRecheable = false;
        }
      } else {
        _isServerRecheable = false;
      }

      await Future.delayed(const Duration(
        seconds: 5,
      ));
    }
  }
}

final networkInfoProvider = Provider((ref) => NetworkInfo());
