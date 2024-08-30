import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppApi {
  AppApi._privateConstructor();

  static final AppApi _instance = AppApi._privateConstructor();

  late final CookieJar cookieJar;

  setupCookieJar() async {
    final Directory appDocumentsDir = await getApplicationSupportDirectory();

    cookieJar = PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage("${appDocumentsDir.path}/cookie"),
    );

    dio.interceptors.add(CookieManager(cookieJar));
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (Response<dynamic> response,
            ResponseInterceptorHandler handler) async {
          currentCookies = await getCookies();
          return handler.next(response);
        },
      ),
    );
  }

  factory AppApi() {
    return _instance;
  }

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  final SharedPreferencesAsync asyncPrefs = SharedPreferencesAsync();

  configureDio() async {
    dio.options.baseUrl = await asyncPrefs.getString("serverUrl") ?? "";
  }

  bool hasServerUrl() {
    return dio.options.baseUrl.trim() != "";
  }

  Future<void> setServerUrl(String url) async {
    await asyncPrefs.setString("serverUrl", url.trim());
    await configureDio();
  }

  String getServerUrl() {
    return dio.options.baseUrl;
  }

  Future<List<Cookie>> getCookies() async {
    return await cookieJar.loadForRequest(Uri.parse(getServerUrl()));
  }

  List<Cookie> currentCookies = [];

  List<Cookie> getCachedCookies() {
    return currentCookies;
  }

  String generateCookieHeader() {
    return (getCachedCookies())
        .map((cookie) => '${cookie.name}=${cookie.value}')
        .join('; ');
  }
}
