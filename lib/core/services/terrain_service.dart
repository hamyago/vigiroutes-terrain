import '../models/terrain_models.dart';
import 'api_service.dart';

class TerrainService {
  static final TerrainService _instance = TerrainService._internal();
  factory TerrainService() => _instance;
  TerrainService._internal();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post(
      '/terrain/auth/login',
      data: {'email': email, 'password': password},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<TerrainBookingModel>> getTodayBookings() async {
    final response = await _api.get('/terrain/bookings/today');
    final data = response.data;
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else {
      list = [];
    }
    return list
        .map((e) => TerrainBookingModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<TerrainBookingModel> scanQrCode(String token) async {
    final response = await _api.post(
      '/terrain/bookings/scan',
      data: {'token': token},
    );
    final data = response.data;
    final bookingData = data is Map && data['data'] is Map
        ? Map<String, dynamic>.from(data['data'] as Map)
        : Map<String, dynamic>.from(data as Map);
    return TerrainBookingModel.fromJson(bookingData);
  }

  Future<void> startInspection(String bookingId) async {
    await _api.post('/terrain/bookings/$bookingId/start');
  }

  Future<void> submitReport(
      String bookingId, Map<String, dynamic> reportData) async {
    await _api.post('/terrain/bookings/$bookingId/report', data: reportData);
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _api.get('/terrain/stats');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
