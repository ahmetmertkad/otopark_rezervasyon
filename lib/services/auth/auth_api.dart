// lib/auth/auth_api.dart
import 'package:dio/dio.dart';
import 'package:otopark_rezervasyon/services/auth/dio_client.dart';

import 'token_storage.dart';

class AuthApi {
  final DioClient client;
  final TokenStorage storage;

  AuthApi({required this.client, required this.storage});

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String password2,
  }) async {
    try {
      await client.dio.post(
        '/account/auth/register/',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'password2': password2,
        },
        options: Options(extra: {'skipAuth': true}),
      );
    } on DioError catch (e) {
      throw _friendlyError(e);
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final r = await client.dio.post(
        '/account/auth/token/',
        data: {'username': username, 'password': password},
        options: Options(extra: {'skipAuth': true}),
      );
      final access = r.data['access'];
      final refresh = r.data['refresh'];
      if (access == null || refresh == null) {
        throw Exception('Sunucudan access/refresh gelmedi.');
      }
      await storage.save(access, refresh);
    } on DioError catch (e) {
      throw _friendlyError(e);
    }
  }

  Future<Map<String, dynamic>> me() async {
    try {
      final r = await client.dio.get('/account/auth/me/');
      return Map<String, dynamic>.from(r.data);
    } on DioError catch (e) {
      throw _friendlyError(e);
    }
  }

  Future<bool> verify(String token) async {
    try {
      await client.dio.post(
        '/account/auth/token/verify/',
        data: {'token': token},
        options: Options(extra: {'skipAuth': true}),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() async {
    final refresh = await storage.refresh;
    if (refresh == null) throw Exception('Refresh token yok.');
    try {
      final r = await client.dio.post(
        '/account/auth/token/refresh/',
        data: {'refresh': refresh},
        options: Options(extra: {'skipAuth': true}),
      );
      final newAccess = r.data['access'];
      if (newAccess == null) throw Exception('Yeni access gelmedi.');
      await storage.save(newAccess, refresh);
    } on DioError catch (e) {
      throw _friendlyError(e);
    }
  }

  Future<void> logout({bool all = false}) async {
    try {
      if (all) {
        await client.dio.post('/account/auth/logout-all/', data: {});
      } else {
        final refresh = await storage.refresh;
        await client.dio.post(
          '/account/auth/logout/',
          data: {'refresh': refresh},
        );
      }
    } on DioError catch (e) {
      throw _friendlyError(e);
    } finally {
      await storage.clear();
    }
  }

  Exception _friendlyError(DioError e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final detail =
        (data is Map && data['detail'] != null)
            ? data['detail'].toString()
            : data?.toString();
    if (status == 400 || status == 401) {
      return Exception(detail ?? 'Kimlik bilgileri hatalı.');
    }
    return Exception('Ağ/Server hatası (${status ?? 'unknown'}): $detail');
  }
}
