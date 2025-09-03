import 'package:flutter/foundation.dart';
import '../services/auth/token_storage.dart';
import '../services/auth/dio_client.dart';
import '../services/auth/auth_api.dart';
import 'package:dio/dio.dart';

class AppConfig {
  final String baseUrl;
  late final TokenStorage storage;
  late final DioClient dioClient;
  late final AuthApi authApi;

  AppConfig._(this.baseUrl);

  static Future<AppConfig> init({required String baseUrl}) async {
    final c = AppConfig._(baseUrl);
    c.storage = TokenStorage();
    c.dioClient = DioClient(baseUrl: baseUrl, storage: c.storage);

    if (kDebugMode) {
      c.dioClient.dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    c.authApi = AuthApi(client: c.dioClient, storage: c.storage);
    return c;
  }
}
