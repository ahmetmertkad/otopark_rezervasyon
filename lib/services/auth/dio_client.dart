import 'dart:async';
import 'package:dio/dio.dart';
import 'token_storage.dart';

class DioClient {
  final Dio dio;
  final TokenStorage storage;

  // Aynı anda birden çok 401 geldiğinde race condition'ı önlemek için
  bool _isRefreshing = false;
  final List<Completer<void>> _refreshWaiters = [];

  DioClient({required String baseUrl, required this.storage})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Access varsa otomatik Bearer ekle
          final access = await storage.access;
          if (access != null && access.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $access';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          // Sadece 401 ise ve request zaten retry edilmiş değilse refresh dene
          if (err.response?.statusCode == 401) {
            final retry = await _handle401AndRefresh(err.requestOptions);
            if (retry != null) return handler.resolve(retry);
          }
          handler.next(err);
        },
      ),
    );
  }

  /// 401 geldiğinde refresh akışı:
  /// - Eşzamanlı 401'leri kuyruklar (tek refresh çağrısı yapılır)
  /// - Refresh başarılıysa orijinal isteği yeniden gönderir
  /// - Refresh başarısızsa null döner (UI logout'a yönlendirir)
  Future<Response<dynamic>?> _handle401AndRefresh(
    RequestOptions failedReq,
  ) async {
    final refresh = await storage.refresh;
    if (refresh == null || refresh.isEmpty) return null;

    // Zaten refresh oluyorsa bekle
    if (_isRefreshing) {
      final waiter = Completer<void>();
      _refreshWaiters.add(waiter);
      await waiter.future; // refresh bittikten sonra devam et
    } else {
      _isRefreshing = true;
      try {
        // Refresh isteğinde Authorization header olmasın
        final r = await dio.post(
          '/account/auth/token/refresh/',
          data: {'refresh': refresh},
          options: Options(headers: {'Authorization': null}),
        );

        // Yeni access (ve rotation açıksa yeni refresh) kaydet
        final newAccess = r.data['access'] as String?;
        final newRefresh = r.data['refresh'] as String?;
        if (newAccess != null) {
          await storage.updateAccess(newAccess);
        }
        if (newRefresh != null) {
          // rotation açıksa backend yeni refresh döndürebilir
          await storage.save(
            newAccess ?? await storage.access ?? '',
            newRefresh,
          );
        }
      } catch (e) {
        // Refresh başarısız → tokenlar silinsin; UI login sayfasına gönderecek
        await storage.clear();
        _isRefreshing = false;
        // Bekleyen herkese haber ver
        for (final c in _refreshWaiters) {
          c.complete();
        }
        _refreshWaiters.clear();
        return null;
      }
      _isRefreshing = false;
      for (final c in _refreshWaiters) {
        c.complete();
      }
      _refreshWaiters.clear();
    }

    // Orijinal isteği yeniden gönder
    final newAccess = await storage.access;
    final opts = Options(
      method: failedReq.method,
      headers: Map<String, dynamic>.from(failedReq.headers)
        ..['Authorization'] = newAccess != null ? 'Bearer $newAccess' : null,
      responseType: failedReq.responseType,
      contentType: failedReq.contentType,
      sendTimeout: failedReq.sendTimeout,
      receiveTimeout: failedReq.receiveTimeout,
    );

    try {
      return await dio.request<dynamic>(
        failedReq.path,
        data: failedReq.data,
        queryParameters: failedReq.queryParameters,
        options: opts,
      );
    } catch (_) {
      return null;
    }
  }
}
