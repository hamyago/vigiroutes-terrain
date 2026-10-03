import 'package:dio/dio.dart';

/// Extrait le message d'erreur le plus utile possible d'une DioException.
///
/// Ordre de priorité :
///   1. Message backend (`response.data['message']` ou `['error']`)
///   2. Message métier selon le code HTTP (fallback)
///   3. Message réseau (timeout, pas de connexion)
///   4. Message générique fourni en paramètre
///
/// IMPORTANT : le message backend est TOUJOURS prioritaire. Sans ça, un 500
/// avec un message clair ("QR token expiré") serait affiché comme
/// "Erreur serveur (500)" — perte totale d'information.
String extractApiError(dynamic e, {String fallback = 'Une erreur est survenue'}) {
  if (e is DioException) {
    // 1. Message backend prioritaire
    final data = e.response?.data;
    if (data is Map) {
      final backendMsg = data['message'] ?? data['error'];
      if (backendMsg != null && backendMsg.toString().trim().isNotEmpty) {
        return backendMsg.toString().trim();
      }
    }

    // 2. Fallback selon le type réseau
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Le serveur met trop de temps à répondre';
      case DioExceptionType.connectionError:
        return 'Pas de connexion réseau';
      case DioExceptionType.badResponse:
        // 3. Fallback selon le code HTTP
        final code = e.response?.statusCode;
        switch (code) {
          case 400:
            return 'Requête invalide';
          case 401:
            return 'Session expirée. Veuillez vous reconnecter.';
          case 403:
            return 'Accès refusé';
          case 404:
            return 'Ressource introuvable';
          case 409:
            return 'Conflit : cette action a déjà été effectuée';
          case 410:
            return 'Ressource expirée. Demandez au client de la régénérer.';
          case 422:
            return 'Données invalides';
          case 429:
            return 'Trop de requêtes. Réessayez dans un instant.';
          case 500:
            return 'Erreur serveur. Contactez le support si le problème persiste.';
          case 503:
            return 'Service temporairement indisponible';
          default:
            return 'Erreur serveur ($code)';
        }
      default:
        break;
    }
  }

  // 4. Fallback string (ancien comportement)
  final msg = e.toString();
  if (msg.contains('SocketException')) return 'Pas de connexion réseau';
  return fallback;
}
