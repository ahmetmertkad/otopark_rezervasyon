// lib/services/parking/parking_api.dart
import 'package:dio/dio.dart';
import '../auth/dio_client.dart';

class ParkingApi {
  final DioClient client;
  ParkingApi(this.client);

  // Backend path (Django: project urls -> 'reservation/', app router -> 'lots')
  static const String lotsPath = '/reservation/lots/';

  /// Otopark listeleme
  Future<List<Map<String, dynamic>>> listLots() async {
    try {
      final r = await client.dio.get(lotsPath);
      final data = r.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['results'] is List) {
        // DRF pagination desteği
        return (data['results'] as List).cast<Map<String, dynamic>>();
      }
      return <Map<String, dynamic>>[];
    } on DioError catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      throw Exception('Listeleme hatası (${status ?? '-'}) ${body ?? ''}');
    }
  }

  /// Otopark oluşturma
  Future<void> createLot({
    required String ad, // örn: "A Blok"
    required String tip, // 'acik' | 'kapali' | 'vip'
    String? konum, // opsiyonel
    required int kapasite, // >= 1
    required bool aktif,
  }) async {
    final body = {
      'ad': ad,
      'tip': tip,
      'konum': konum ?? '',
      'kapasite': kapasite,
      'aktif': aktif,
    };
    try {
      await client.dio.post(lotsPath, data: body);
    } on DioError catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      throw Exception('Oluşturma hatası (${status ?? '-'}) ${body ?? ''}');
    }
  }
}
