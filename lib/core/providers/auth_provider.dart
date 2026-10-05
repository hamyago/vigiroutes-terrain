// lib/core/providers/auth_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/terrain_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = true;
  String? _error;
  bool _isAuthenticated = false;
  String? _agentName;
  String? _centerName;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String? get agentName => _agentName;
  String? get centerName => _centerName;

  // ── Rôle transporteur CT ───────────────────────────────────────────────
  bool _isCtTransporter = false;
  String? _ctTransporterType; // 'tow' | 'driver'

  /// Vrai si l'agent connecté est aussi transporteur CT
  /// (remorqueur ou chauffeur) — utilisé pour afficher les missions.
  bool get isCtTransporter => _isCtTransporter;

  /// Type de transporteur : 'tow' (remorqueur) ou 'driver' (chauffeur).
  /// Null si l'agent n'est pas transporteur.
  String? get ctTransporterType => _ctTransporterType;

  final TerrainService _service = TerrainService.instance;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('sanctum_token');
      if (token != null && token.isNotEmpty) {
        _agentName = prefs.getString('agent_name');
        _centerName = prefs.getString('center_name');
        _isCtTransporter = prefs.getBool('is_ct_transporter') ?? false;
        _ctTransporterType = prefs.getString('ct_transporter_type');
        _isAuthenticated = true;

        // ✅ Ré-envoyer le token FCM au backend à chaque démarrage
        // (le token FCM peut changer au fil du temps)
        TerrainNotificationService.instance.sendTokenToBackend();
      } else {
        _isAuthenticated = false;
      }
    } catch (_) {
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.login(email, password);
      final token = result['token']?.toString() ?? result['access_token']?.toString() ?? '';
      if (token.isEmpty) {
        _error = 'Token manquant dans la réponse';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sanctum_token', token);

      final agentData = result['agent'] as Map<String, dynamic>?;
      _agentName = agentData?['name']?.toString() ??
          agentData?['full_name']?.toString() ??
          result['name']?.toString() ?? '';
      final ctPartner = agentData?['ct_partner'] as Map<String, dynamic>?;
      _centerName = agentData?['center_name']?.toString() ??
          ctPartner?['name']?.toString() ??
          result['center_name']?.toString() ?? '';

      // Détecter le rôle transporteur CT
      _isCtTransporter = result['is_ct_transporter'] == true;
      _ctTransporterType = result['ct_transporter_type']?.toString();

      await prefs.setString('agent_name', _agentName ?? '');
      await prefs.setString('center_name', _centerName ?? '');
      await prefs.setBool('is_ct_transporter', _isCtTransporter);
      if (_ctTransporterType != null) {
        await prefs.setString('ct_transporter_type', _ctTransporterType!);
      }

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();

      // ✅ Envoyer le token FCM au backend (post-login)
      TerrainNotificationService.instance.sendTokenToBackend();

      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sanctum_token');
    await prefs.remove('agent_name');
    await prefs.remove('center_name');
    await prefs.remove('is_ct_transporter');
    await prefs.remove('ct_transporter_type');
    _isAuthenticated = false;
    _agentName = null;
    _centerName = null;
    _isCtTransporter = false;
    _ctTransporterType = null;
    notifyListeners();
  }

  // FIX : utiliser DioException typé au lieu de string-matching sur e.toString().
  String _extractError(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.connectionError:
          return 'Impossible de se connecter au serveur';
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode;
          if (code == 401 || code == 403) {
            return 'Email ou mot de passe incorrect';
          }
          return 'Erreur serveur ($code)';
        default:
          break;
      }
    }
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('Unauthorized')) {
      return 'Email ou mot de passe incorrect';
    }
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'Impossible de se connecter au serveur';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}