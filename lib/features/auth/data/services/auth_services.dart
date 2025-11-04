import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:huystore/core/network/dio_client.dart';
import 'package:huystore/core/services/token_storage.dart';
import 'package:huystore/global.dart';
import 'package:path/path.dart';

class AuthService {
  final Dio _dio = DioClient().dio;

  Future<Response> login(String username, String password) async {
    final res = await _dio.post(
      "user/login",
      data: {"UserName": username, "Password": password},
    );
    if (res.statusCode == 200) {
      final resultData = res.data;
      if (resultData['statusCode'] != 200) {
        res.statusCode = resultData['statusCode'];
        res.statusMessage = resultData['message'];
        return res;
      }
      final data = resultData['data'];
      await TokenStorage.saveAccessToken(data["token"]);
      await TokenStorage.saveRefreshToken(data["refreshToken"]);
      await TokenStorage.saveUser(data);
      final fcmToken = await FirebaseMessaging.instance.getToken();
      // print('FCM Token: $fcmToken');
      final platform = Platform.isAndroid ? 'android' : 'ios';
      // String fullPathAvatar=(dotenv.env['FILE_URL'] ?? "") + data["avatarUrl"];
      // _updateAvatarOnAppBar(fullPathAvatar);
      await _dio.post(
        "user/device",
        data: {"deviceId": fcmToken, "platform": platform}
      );
      return res;
    }
    return res;
  }

  void _updateAvatarOnAppBar(String? url) {
    globalAvatarUrl.value = url;
  }

  Future<Map<String, dynamic>> register({
    required String userName,
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        'user/register',
        data: {
          'UserName': userName,
          'FullName': fullName,
          'Email': email,
          'PhoneNumber': phone,
          'Password': password,
        },
      );
      return res.data;
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Response?> uploadFile(File file, String uploadUrl) async {
    try {
      // Lấy token từ TokenStorage
      String? accessToken = await TokenStorage.getAccessToken();

      if (accessToken == null) {
        print("Access token not found.");
        return null;
      }

      // Tạo form data chứa file
      String fileName = basename(file.path);
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      // Gửi request
      Response response = await _dio.post(
        uploadUrl,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $accessToken",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      return response;
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> logout(Map<String, dynamic> userLogin) async {
    try {
      // Perform the POST request using DioClient
      final response = await _dio.post(
        'user/logout', // Endpoint for logout
        data: TokenStorage.getUser(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      // Check if the request was successful (HTTP 200 OK)
      if (response.statusCode == 200) {
        // Reset user login data
        userLogin.clear(); // Clears the user login data

        // Optionally clear user session or token in storage
        // sharedPreferences.remove(sessionUserCatch);  // Use shared_preferences for local storage

        // Print a success message
        print("User logged out successfully");

        // Optionally, navigate to the home screen (using Navigator)
        // Navigator.pushReplacementNamed(context, '/');

        return {'status': 'success', 'message': 'Logged out successfully'};
      } else {
        return {'status': 'error', 'message': 'Failed to log out'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'An error occurred: $e'};
    }
  }

  Map<String, dynamic> _handleError(DioException e) {
    return {
      'statusCode': e.response?.statusCode ?? 500,
      'message': e.response?.data?['message'] ?? e.message,
    };
  }
}
