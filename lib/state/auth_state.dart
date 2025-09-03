import 'package:flutter/foundation.dart';
import '../services/auth/auth_api.dart';
import '../services/auth/token_storage.dart';

class AuthState extends ChangeNotifier {
  final AuthApi api;
  final TokenStorage storage;

  bool loading = true;
  bool authed = false;

  AuthState(this.api, this.storage);

  /// Uygulama açılışında çağır: token varsa /me ile doğrula
  Future<void> bootstrap() async {
    try {
      final acc = await storage.access;
      if (acc == null || acc.isEmpty) {
        authed = false;
      } else {
        await api
            .me(); // access geçerliyse 200 döner; gerekirse interceptor refresh eder.
        authed = true;
      }
    } catch (_) {
      authed = false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> doLogout({bool all = false}) async {
    try {
      await api.logout(all: all);
    } finally {
      authed = false;
      notifyListeners();
    }
  }
}
