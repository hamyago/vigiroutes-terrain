import '../../core/services/api_service.dart';
import '../models/terrain_models.dart';

class TerrainService {
  static final TerrainService instance = TerrainService._();
  TerrainService._();

  final _api = ApiService();

  /// Authentification de l'agent terrain.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post(
      '/v1/terrain/login',
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Fetch all bookings scheduled for today at this agent's assigned center.
  Future<List<TerrainBookingModel>> getTodayBookings() async {
    final response = await _api.get('/v1/terrain/today-bookings');
    final List data = response.data['data'] as List? ?? [];
    return data
        .map((e) => TerrainBookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Scan a client QR code token.
  Future<TerrainBookingModel> scanQr(String token) async {
    final response = await _api.post(
      '/v1/terrain/scan-qr',
      data: {'token': token},
    );
    final data = response.data['data'];
    if (data is Map<String, dynamic>) {
      final bookingMap = data.containsKey('booking')
          ? data['booking'] as Map<String, dynamic>
          : data;
      return TerrainBookingModel.fromJson(bookingMap);
    }
    throw Exception('Réponse inattendue du serveur');
  }

  /// Démarre l'inspection d'une réservation (status → inspection_in_progress).
  Future<void> startInspection(String bookingId) async {
    await _api.post(
      '/v1/terrain/bookings/$bookingId/start-inspection',
      data: {},
    );
  }

  /// Soumet le rapport d'inspection final.
  Future<void> submitReport(String bookingId, Map<String, dynamic> data) async {
    await _api.post(
      '/v1/terrain/bookings/$bookingId/final-report',
      data: data,
    );
  }

  /// Fetch dashboard statistics for the terrain agent.
  Future<TerrainDashboardModel> getDashboard({String? date}) async {
    final response = await _api.get(
      '/v1/terrain/dashboard',
      params: date != null ? {'date': date} : null,
    );
    return TerrainDashboardModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
