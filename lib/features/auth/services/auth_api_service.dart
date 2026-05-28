import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/services/auth_service.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});
  final String token;
  final Map<String, dynamic> user;
}

class AuthApiException implements Exception {
  AuthApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthApiService {
  AuthApiService._();

  /// Logs in. Throws [AuthApiException] on any failure.
  /// On success, token & user are persisted to SecureStorage.
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await ApiClient.instance.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final body = res.data;
      if (body is! Map || body['success'] != true) {
        throw AuthApiException(
          body is Map ? (body['message']?.toString() ?? 'Login gagal') : 'Login gagal',
          statusCode: res.statusCode,
        );
      }

      final data = body['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = Map<String, dynamic>.from(data['user'] as Map);

      // Client-side role gate per API_CONTRACT §2.1.
      final role = user['role']?.toString();
      if (role == 'customer') {
        throw AuthApiException(
          'Akun ini bukan akun staff',
          statusCode: 403,
        );
      }
      if (role != 'kasir' && role != 'admin') {
        throw AuthApiException(
          'Role tidak diizinkan: $role',
          statusCode: 403,
        );
      }

      // is_active gate (backend already returns 403 if inactive, but double-check).
      if (user['is_active'] == false) {
        throw AuthApiException(
          'Akun kamu dinonaktifkan',
          statusCode: 403,
        );
      }

      await AuthService.saveToken(token);
      await AuthService.saveUser(user);

      return AuthResult(token: token, user: user);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Logs out on server then clears local token. Errors are swallowed.
  static Future<void> logout() async {
    try {
      await ApiClient.instance.post(ApiEndpoints.logout);
    } on DioException {
      // ignore — local clear still runs.
    } finally {
      await AuthService.clearToken();
    }
  }

  /// Uploads FCM token to backend.
  static Future<void> updateFcmToken(String fcmToken) async {
    try {
      await ApiClient.instance.patch(
        ApiEndpoints.fcmToken,
        data: {'fcm_token': fcmToken},
      );
    } on DioException {
      // non-fatal
    }
  }

  static AuthApiException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? msg;
    if (data is Map && data['message'] is String) {
      msg = data['message'] as String;
    }

    switch (status) {
      case 401:
        return AuthApiException(
          msg ?? 'Email atau password salah',
          statusCode: 401,
        );
      case 403:
        return AuthApiException(
          msg ?? 'Akun kamu dinonaktifkan',
          statusCode: 403,
        );
      case 422:
        return AuthApiException(
          msg ?? 'Data tidak valid',
          statusCode: 422,
        );
      case 429:
        return AuthApiException(
          msg ?? 'Terlalu banyak percobaan login. Coba lagi sebentar.',
          statusCode: 429,
        );
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return AuthApiException('Koneksi timeout. Coba lagi.');
        }
        if (e.type == DioExceptionType.connectionError) {
          return AuthApiException('Tidak dapat terhubung ke server.');
        }
        return AuthApiException(msg ?? 'Terjadi kesalahan jaringan.');
    }
  }
}
