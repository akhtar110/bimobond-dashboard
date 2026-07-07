import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/DeviceInfoService/device_info_service.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/utils/api_response_parser.dart';
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

      final userCredential = await _auth.signInWithPopup(googleProvider);

      final user = userCredential.user;

      if (user == null) {
        throw Exception('googleSignInCancelled');
      }

      final idToken = await user.getIdToken(true);

      return await _sendToBackend(idToken!);
    } on FirebaseAuthException catch (e) {
      throw Exception(_googleAuthErrorMessage(e));
    } catch (e) {
      throw Exception(_googleAuthErrorMessage(e));
    }
  }

  String _googleAuthErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      if (_isGoogleSignInCancelled(e.code)) {
        return 'googleSignInCancelled';
      }
      return e.message ?? 'Google auth error';
    }

    if (e is Exception) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (_isGoogleSignInCancelled(message)) {
        return 'googleSignInCancelled';
      }
      return message;
    }

    final message = e.toString();
    if (_isGoogleSignInCancelled(message)) {
      return 'googleSignInCancelled';
    }

    return message;
  }

  bool _isGoogleSignInCancelled(String value) {
    return value.contains('popup-closed-by-user') ||
        value.contains('popup_closed') ||
        value.contains('cancelled-popup-request') ||
        value == 'googleSignInCancelled';
  }

  /// ================================
  /// SHARED BACKEND CALL
  /// ================================
  Future<Map<String, dynamic>> _sendToBackend(String idToken) async {
    if (ApiConfig.requiresHostedApiSetup()) {
      throw Exception(ApiConfig.missingConfigMessage);
    }

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
        if (ApiConfig.usesHostedApiProxy) {
          throw Exception(
            'API proxy not deployed. Upgrade Firebase to Blaze and run '
            'firebase deploy --only functions, or host the dashboard at '
            '${ApiConfig.backendUrl} (see scripts/deploy_droplet.ps1).',
          );
        }
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

      try {
        return ApiResponseParser.unwrapAuthPayload(response.data);
      } on FormatException catch (e) {
        final base = ApiConfig.resolve();
        throw Exception(
          '${e.message} (API base: ${base.isEmpty ? Uri.base.origin : base})',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        final base = ApiConfig.resolve();
        final hint = ApiConfig.usesHostedApiProxy
            ? 'The API proxy could not reach ${ApiConfig.backendUrl}. '
                'Deploy Firebase Functions (apiProxy) and ensure the server is online.'
            : base.isEmpty
                ? 'API URL is not configured for this host. Set API_BASE_URL via '
                    '--dart-define or web/app_config.js, then rebuild and redeploy.'
                : 'Check that $base is reachable and CORS allows this site.';
        throw Exception('Connection failed → $hint');
      }

      throw Exception(e.response?.data ?? e.message);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}