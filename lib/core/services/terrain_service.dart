import '../../core/services/api_service.dart';
import '../models/terrain_models.dart';

class TerrainService {
  static final TerrainService instance = TerrainService._();
  TerrainService._();

  final _api = ApiService();

  /// Authentification de l'agent terrain.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post(
      '/terrain/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Fetch all bookings scheduled for today at this agent's assigned center.
  Future<List<TerrainBookingModel>> getTodayBookings() async {
    final response = await _api.get('/terrain/bookings/today');
    final List data = response.data['data'] as List? ?? [];
    return data
        .map((e) => TerrainBookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Scan a client QR code token.
  Future<TerrainBookingModel> scanQr(String token) async {
    final response = await _api.post(
      '/terrain/bookings/scan',
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

  /// Démarre l'inspection d'une réservation (status → in_progress).
  Future<void> startInspection(String bookingId) async {
    await _api.post(
      '/terrain/bookings/$bookingId/start',
      data: {},
    );
  }

  /// Soumet le rapport d'inspection final.
  Future<void> submitReport(String bookingId, Map<String, dynamic> data) async {
    await _api.post(
      '/terrain/bookings/$bookingId/report',
      data: data,
    );
  }

  /// Fetch dashboard statistics for the terrain agent.
  Future<TerrainDashboardModel> getDashboard({String? date}) async {
    final response = await _api.get(
      '/terrain/stats',
      params: date != null ? {'date': date} : null,
    );
    return TerrainDashboardModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Retourne la liste des centres assignés à l'agent.
  Future<List<Map<String, dynamic>>> getCenters() async {
    final response = await _api.get('/terrain/centers');
    final List data = response.data['data'] as List? ?? [];
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Met à jour les coordonnées GPS d'un centre CT.
  /// [centerId] : UUID du centre à géolocaliser.
  /// [latitude] / [longitude] : coordonnées GPS obtenues via Geolocator.
  /// [address] : adresse lisible optionnelle (reverse geocoding).
  Future<void> updateCenterGps({
    required String centerId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    await _api.patch(
      '/terrain/centers/$centerId/gps',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
      },
    );
  }
}
