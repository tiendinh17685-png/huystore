import 'package:dio/dio.dart';
import 'package:huystore/core/network/dio_client.dart';

class ApiService {
  final Dio _dio = DioClient().dio;

  Future<Response> get(String path, {Map<String, dynamic>? query}) {
    return _dio.get(path, queryParameters: query);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  /**
 * 
 */
  Future<Response> uploadFile(
    String path,
    String filePath,
    String subPath,
  ) async {
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(filePath),
      "subPath": subPath,
    });
    return _dio.post(path, data: formData);
  }
}
