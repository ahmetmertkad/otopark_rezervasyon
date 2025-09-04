import 'package:otopark_rezervasyon/services/auth/auth_api.dart';
import 'package:otopark_rezervasyon/services/auth/dio_client.dart';
import 'package:otopark_rezervasyon/services/auth/token_storage.dart';
import 'package:otopark_rezervasyon/services/parking/parking_api.dart';

class AppConfig {
  final DioClient dio;
  final TokenStorage storage;
  final AuthApi authApi;
  final ParkingApi parkingApi; // <-- eklendi

  AppConfig({
    required this.dio,
    required this.storage,
    required this.authApi,
    required this.parkingApi, // <-- eklendi
  });

  static Future<AppConfig> init({required String baseUrl}) async {
    final storage = TokenStorage();
    final dio = DioClient(baseUrl: baseUrl, storage: storage);
    final authApi = AuthApi(client: dio, storage: storage);
    final parkingApi = ParkingApi(dio); // <-- eklendi
    return AppConfig(
      dio: dio,
      storage: storage,
      authApi: authApi,
      parkingApi: parkingApi, // <-- eklendi
    );
  }
}
