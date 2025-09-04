// lib/net/dio_client.dart
import 'dart:async';
import 'package:dio/dio.dart';
import '../auth/token_storage.dart';

class DioClient {
  final Dio dio;
  final TokenStorage storage;

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
    // Log interceptor – isteği görüyor musun diye
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        requestHeader: true,
        responseBody: true,
        error: true,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Login/Register/Verify/Refresh gibi çağrılarda auth ekleme
          if (options.extra['skipAuth'] == true) {
            return handler.next(options);
          }
          final access = await storage.access;
          if (access != null && access.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $access';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          if (err.response?.statusCode == 401) {
            final retry = await _handle401AndRefresh(err.requestOptions);
            if (retry != null) {
              return handler.resolve(retry);
            }
          }
          handler.next(err);
        },
      ),
    );
  }

  Future<Response<dynamic>?> _handle401AndRefresh(
    RequestOptions failedReq,
  ) async {
    final refresh = await storage.refresh;
    if (refresh == null || refresh.isEmpty) return null;

    if (_isRefreshing) {
      final waiter = Completer<void>();
      _refreshWaiters.add(waiter);
      await waiter.future;
    } else {
      _isRefreshing = true;
      try {
        final r = await dio.post(
          '/account/auth/token/refresh/',
          data: {'refresh': refresh},
          options: Options(
            headers: {'Authorization': null},
            extra: {'skipAuth': true}, // güvenli olsun
          ),
        );

        final newAccess = r.data['access'] as String?;
        final newRefresh = r.data['refresh'] as String?;
        if (newAccess != null && newAccess.isNotEmpty) {
          await storage.updateAccess(newAccess);
        }
        if (newRefresh != null && newRefresh.isNotEmpty) {
          final acc = await storage.access ?? '';
          await storage.save(acc, newRefresh);
        }
      } catch (_) {
        await storage.clear();
      } finally {
        _isRefreshing = false;
        for (final c in _refreshWaiters) {
          c.complete();
        }
        _refreshWaiters.clear();
      }
    }

    final newAccess = await storage.access;
    final opts = Options(
      method: failedReq.method,
      headers: Map<String, dynamic>.from(failedReq.headers)
        ..['Authorization'] =
            (newAccess != null && newAccess.isNotEmpty)
                ? 'Bearer $newAccess'
                : null,
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
