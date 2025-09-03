// lib/auth/token_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  final _s = const FlutterSecureStorage();

  Future<void> save(String access, String refresh) async {
    await _s.write(key: _kAccess, value: access);
    await _s.write(key: _kRefresh, value: refresh);
  }

  Future<String?> get access async => _s.read(key: _kAccess);
  Future<String?> get refresh async => _s.read(key: _kRefresh);

  Future<void> clear() async {
    await _s.delete(key: _kAccess);
    await _s.delete(key: _kRefresh);
  }

  Future<void> updateAccess(String access) async {
    await _s.write(key: _kAccess, value: access);
  }
}
