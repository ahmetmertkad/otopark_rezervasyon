import 'package:dio/dio.dart';
import 'dio_client.dart';
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
    await client.dio.post(
      '/account/auth/register/',
      data: {
        'username': username,
        'email': email,
        'password': password,
        'password2': password2,
      },
      options: Options(headers: {'Authorization': null}),
    );
  }

  Future<void> login(String username, String password) async {
    final r = await client.dio.post(
      '/account/auth/token/',
      data: {'username': username, 'password': password},
      options: Options(headers: {'Authorization': null}),
    );
    await storage.save(r.data['access'], r.data['refresh']);
  }

  Future<Map<String, dynamic>> me() async {
    final r = await client.dio.get('/account/auth/me/');
    return Map<String, dynamic>.from(r.data);
  }

  Future<bool> verify(String token) async {
    try {
      await client.dio.post(
        '/account/auth/token/vserify/',
        data: {'token': token},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout({bool all = false}) async {
    if (all) {
      await client.dio.post('/account/auth/logout-all/', data: {});
    } else {
      final refresh = await storage.refresh;
      await client.dio.post(
        '/account/auth/logout/',
        data: {'refresh': refresh},
      );
    }
    await storage.clear();
  }
}
