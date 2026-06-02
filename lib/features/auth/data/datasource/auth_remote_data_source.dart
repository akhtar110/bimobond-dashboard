import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/DeviceInfoService/device_info_service.dart';
import '../models/login_request_model.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final Dio _dio;
  // final GoogleSignIn _googleSignIn;

  AuthRemoteDataSource(
      this._auth,
      this._dio,
      // this._googleSignIn,
      );

  /// ================================
  /// EMAIL / PASSWORD LOGIN
  /// ================================
  Future<Map<String, dynamic>> login(LoginRequestModel request) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception("Firebase user is null");
      }

      final idToken = await user.getIdToken();

      if (idToken == null || idToken.isEmpty) {
        throw Exception("Failed to get Firebase ID token");
      }

      return await _sendToBackend(idToken);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Firebase auth error");
    } catch (e) {
      rethrow;
    }
  }

  /// ================================
  /// GOOGLE LOGIN
  /// ================================
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();

      final userCredential =
      await _auth.signInWithPopup(googleProvider);

      final user = userCredential.user;

      if (user == null) {
        throw Exception("Firebase user is null after Google login");
      }

      final idToken = await user.getIdToken(true);

      return await _sendToBackend(idToken!);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Google auth error");
    }
  }

  /// ================================
  /// SHARED BACKEND CALL
  /// ================================
  Future<Map<String, dynamic>> _sendToBackend(String idToken) async {
    try {
      final deviceData = await DeviceInfoService.collect();

      final response = await _dio.post(
        '/auth/login',
        data: deviceData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          followRedirects: false,
          validateStatus: (status) =>
          status != null && status < 500,
        ),
      );

      if (response.statusCode == 404) {
        throw Exception(
          "404 NOT FOUND → Backend route mismatch. Check /auth/login",
        );
      }

      if (response.statusCode == 401) {
        throw Exception("Unauthorized → Invalid Firebase token");
      }

      if (response.statusCode == null ||
          response.statusCode! >= 400) {
        throw Exception("Backend error: ${response.statusCode}");
      }

      final data = response.data;

      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);

      throw Exception("Invalid backend response format");
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          "Connection failed → CORS or backend unreachable",
        );
      }

      throw Exception(e.response?.data ?? e.message);
    }
  }
}