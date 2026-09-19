import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _baseUrl = 'https://api.vigiroutes.com/api';

  Dio _buildDio(String? token) {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
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
    final token = await _getToken();
    final dio = _buildDio(token);
    return dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) async {
    final token = await _getToken();
    final dio = _buildDio(token);
    return dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    final token = await _getToken();
    final dio = _buildDio(token);
    return dio.patch(path, data: data);
  }
}
