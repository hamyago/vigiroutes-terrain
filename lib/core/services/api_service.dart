import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _baseUrl = 'https://api.vigiroutes.com/api';

  // FIX : instance Dio unique avec intercepteur — l'ancien code créait une
  // nouvelle instance à chaque appel, ce qui empêche le pooling de connexion
  // et les intercepteurs. Le token est injecté dynamiquement.
  late final Dio _dio = _buildDio();

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Injecte le token Bearer avant chaque requête.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    return dio;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sanctum_token');
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return _dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return _dio.patch(path, data: data);
  }

  /// Upload multipart (S16.1 — photos véhicule).
  /// Le header Content-Type est forcé à multipart/form-data par Dio,
  /// il ne faut PAS le passer en JSON.
  Future<Response> postMultipart(
    String path, {
    required FormData data,
  }) async {
    return _dio.post(
      path,
      data: data,
      options: Options(
        contentType: 'multipart/form-data',
        // Augmente le timeout pour les uploads (30s par défaut côté Dio)
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }
}
