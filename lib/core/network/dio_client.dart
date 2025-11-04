import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:huystore/core/services/token_storage.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late Dio dio;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_URL'] ?? '',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 35),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // thêm token nếu có
          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          print('❌ Dio error: ${e.message}');
          print('👉 Status code: ${e.response?.statusCode}');
          print('👉 Response data: ${e.response?.data}');
          if (e.response?.statusCode == 401) {
            final refresh = await TokenStorage.getRefreshToken();
            if (refresh != null) {
              try {
                final newToken = await _refreshToken(refresh);
                // Update token vào dio
                dio.options.headers["Authorization"] = "Bearer $newToken";
                // Retry request cũ
                final opts = e.requestOptions;
                final cloneReq = await dio.request(
                  opts.path,
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                  options: Options(
                    method: opts.method,
                    headers: opts.headers
                      ..["Authorization"] = "Bearer $newToken",
                  ),
                );
                return handler.resolve(cloneReq);
              } catch (_) {
                await TokenStorage.clear();
                navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// dùng Dio riêng không có interceptor để tránh vòng lặp 401
  Future<String> _refreshToken(String refreshToken) async {
    final tmpDio = Dio(BaseOptions(baseUrl: dotenv.env['API_URL'] ?? ''));
    try {
      final res = await tmpDio.get(
        "/user/refreshaccesstoken",
        queryParameters: {"tokenRefresh": refreshToken},
      );
      print("Refresh response: ${res.data}");
      final newAccessToken = res.data["data"];

      if (newAccessToken == null) {
        throw Exception("Refresh failed: accessToken is null");
      }

      // Lưu lại token mới
      await TokenStorage.saveAccessToken(newAccessToken);
      if (newAccessToken != null) {
        await TokenStorage.saveAccessToken(newAccessToken);
      }

      return newAccessToken;
    } catch (e) {
      print("Refresh token error: $e");
      rethrow;
    }
  }
}
