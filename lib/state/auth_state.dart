// lib/state/auth_state.dart
import 'package:flutter/foundation.dart';
import 'package:otopark_rezervasyon/services/auth/auth_api.dart';
import 'package:otopark_rezervasyon/services/auth/token_storage.dart';

class AuthState extends ChangeNotifier {
  final AuthApi api;
  final TokenStorage storage;

  bool loading = true;
  bool authed = false;
  bool busy = false;
  String? errorText;

  AuthState(this.api, this.storage);

  Future<void> bootstrap() async {
    final acc = await storage.access;
    authed = acc != null && acc.isNotEmpty;
    loading = false;
    notifyListeners();
  }

  Future<void> login(String u, String p) async {
    busy = true;
    errorText = null;
    notifyListeners();
    try {
      await api.login(u, p);
      authed = true;
    } catch (e) {
      errorText = e.toString();
      authed = false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    busy = true;
    notifyListeners();
    try {
      await api.logout();
    } catch (_) {
      // sessiz geç
    } finally {
      await storage.clear();
      authed = false;
      busy = false;
      notifyListeners();
    }
  }
}
