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

  /// Charge toutes les réservations prévues aujourd'hui pour ce centre.
  Future<List<TerrainBookingModel>> getTodayBookings() async {
    final response = await _api.get('/terrain/bookings/today');
    final List data = response.data['data'] as List? ?? [];
    return data
        .map((e) => TerrainBookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// FIX #3 : Charge un booking spécifique par son ID.
  /// Utile quand la notification push arrive pour un booking hors planning du jour.
  /// Endpoint backend à créer : GET /terrain/bookings/{id}
  Future<TerrainBookingModel> getBookingById(String id) async {
    final response = await _api.get('/terrain/bookings/$id');
    final data = response.data['data'];
    if (data is Map<String, dynamic>) {
      return TerrainBookingModel.fromJson(data);
    }
    throw Exception('Réponse inattendue du serveur pour le booking $id');
  }

  /// Scanne un QR code client.
  /// Le backend doit mettre le booking en statut 'arrived' et envoyer
  /// une notification FCM au client.
  Future<TerrainBookingModel> scanQr(String token) async {
    final response = await _api.post(
      '/terrain/bookings/scan',
      data: {'token': token},
    );
    final data = response.data['data'];
    if (data is Map<String, dynamic>) {
      // Le backend peut renvoyer {booking: {...}} ou directement {...}
      final bookingMap = data.containsKey('booking')
          ? data['booking'] as Map<String, dynamic>
          : data;
      return TerrainBookingModel.fromJson(bookingMap);
    }
    throw Exception('Réponse inattendue du serveur lors du scan');
  }

  /// Démarre l'inspection d'une réservation (status → in_progress).
  /// Le backend doit envoyer une notification FCM au client.
  Future<void> startInspection(String bookingId) async {
    await _api.post(
      '/terrain/bookings/$bookingId/start',
      data: {},
    );
  }

  /// Soumet le rapport d'inspection final.
  /// Le backend doit :
  /// - mettre le booking en statut result (favorable/defavorable/contre_visite)
  /// - envoyer une notification FCM au client avec le résultat
  Future<void> submitReport(String bookingId, Map<String, dynamic> data) async {
    await _api.post(
      '/terrain/bookings/$bookingId/report',
      data: data,
    );
  }

  /// Charge les statistiques du dashboard pour la date donnée (défaut = aujourd'hui).
  Future<TerrainDashboardModel> getDashboard({String? date}) async {
    final response = await _api.get(
      '/terrain/stats',
      params: date != null ? {'date': date} : null,
    );
    return TerrainDashboardModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Retourne la liste des centres CT assignés à cet agent.
  Future<List<Map<String, dynamic>>> getCenters() async {
    final response = await _api.get('/terrain/centers');
    final List data = response.data['data'] as List? ?? [];
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Met à jour les coordonnées GPS d'un centre CT.
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
