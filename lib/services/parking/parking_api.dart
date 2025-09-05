import 'package:dio/dio.dart';
import '../auth/dio_client.dart';

class ParkingApi {
  final DioClient client;
  ParkingApi(this.client);

  // ---------------- OTOPARK ----------------
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
    String? konum,
    required int kapasite,
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

  // ---------------- RATE PLAN ----------------
  static const String ratePlansPath = '/reservation/rateplans/';

  /// Tarife listeleme (lotId verilirse filtreler)
  Future<List<Map<String, dynamic>>> listRatePlans({int? lotId}) async {
    try {
      final r = await client.dio.get(
        ratePlansPath,
        queryParameters: lotId != null ? {'lot': lotId} : null,
      );
      final data = r.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['results'] is List) {
        return (data['results'] as List).cast<Map<String, dynamic>>();
      }
      return <Map<String, dynamic>>[];
    } on DioError catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      throw Exception(
        'Tarife listeleme hatası (${status ?? '-'}) ${body ?? ''}',
      );
    }
  }

  /// Tarife oluşturma
  Future<void> createRatePlan({
    required int lot,
    required String ad,
    required String saatlikUcret,
    String? gunlukTavan,
  }) async {
    final body = {
      'lot': lot,
      'ad': ad,
      'saatlik_ucret': saatlikUcret,
      'gunluk_tavan': gunlukTavan,
    };
    try {
      await client.dio.post(ratePlansPath, data: body);
    } on DioError catch (e) {
      final status = e.response?.statusCode;
      final resBody = e.response?.data;
      throw Exception(
        'Tarife oluşturma hatası (${status ?? '-'}) ${resBody ?? ''}',
      );
    }
  }

  /// Tarife güncelleme (PATCH)
  Future<void> updateRatePlan({
    required int id,
    String? ad,
    String? saatlikUcret,
    String? gunlukTavan,
    int? lot,
  }) async {
    final Map<String, dynamic> body = {};
    if (ad != null) body['ad'] = ad;
    if (saatlikUcret != null) body['saatlik_ucret'] = saatlikUcret;
    if (gunlukTavan != null) body['gunluk_tavan'] = gunlukTavan;
    if (lot != null) body['lot'] = lot;

    try {
      await client.dio.patch('$ratePlansPath$id/', data: body);
    } on DioError catch (e) {
      final status = e.response?.statusCode;
      final resBody = e.response?.data;
      throw Exception(
        'Tarife güncelleme hatası (${status ?? '-'}) ${resBody ?? ''}',
      );
    }
  }

  /// Tarife silme
  Future<void> deleteRatePlan(int id) async {
    try {
      await client.dio.delete('$ratePlansPath$id/');
    } on DioError catch (e) {
      final status = e.response?.statusCode;
      final resBody = e.response?.data;
      throw Exception(
        'Tarife silme hatası (${status ?? '-'}) ${resBody ?? ''}',
      );
    }
  }
}
