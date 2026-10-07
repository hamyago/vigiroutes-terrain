// lib/core/services/notification_service.dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'alert_service.dart';

/// Gère les notifications push FCM pour l'app Terrain (agents CT).
///
/// Types FCM attendus depuis le backend :
///   - booking_confirmed    → nouvelle réservation CT assignée à ce centre
///   - vehicle_at_center    → client arrivé avec son véhicule
///   - transport_update     → mise à jour transport/remorquage vers le centre
///   - ct_mission_assigned  → mission transport assignée à ce transporteur
///   - vt_reminder_30d/15d/7d → rappels CT pour les clients du centre
///   - vt_expired           → CT expiré (action requise côté centre)
///
/// Usage : TerrainNotificationService.instance.init(navigatorKey, localNotifications)
class TerrainNotificationService {
  TerrainNotificationService._();
  static final instance = TerrainNotificationService._();

  late FlutterLocalNotificationsPlugin _localNotifications;
  GlobalKey<NavigatorState>? _navigatorKey;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> init(
    GlobalKey<NavigatorState> navigatorKey,
    FlutterLocalNotificationsPlugin localNotifications,
  ) async {
    _navigatorKey = navigatorKey;
    _localNotifications = localNotifications;

    // NE PAS awaiter requestPermission ici — cela bloque le démarrage sur iOS
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseMessaging.instance.requestPermission(
        alert: true, sound: true, badge: true,
      );
    });

    // Tap sur notification → app en arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Cold start depuis une notification
    unawaited(
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) _handleTap(message);
      }),
    );

    // Foreground : Android n'affiche pas les FCM automatiquement
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // ✅ Enregistrer le token FCM dès l'init (si déjà loggé, le token
    // est envoyé ; sinon la requête échoue silencieusement avec 401)
    unawaited(sendTokenToBackend());
  }

  // ── Envoi du token FCM au backend ──────────────────────────────────────────

  /// Récupère le token FCM et l'envoie au backend.
  /// À appeler après login réussi ET à l'init.
  Future<void> sendTokenToBackend() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        debugPrint('[Notification] Pas de FCM token disponible');
        return;
      }

      await ApiService().post(
        '/terrain/auth/fcm-token',
        data: {'fcm_token': fcmToken},
      );

      debugPrint('[Notification] FCM token envoyé: ${fcmToken.substring(0, 20)}...');
    } catch (e) {
      debugPrint('[Notification] Erreur envoi FCM token: $e');
    }
  }

  // ── Foreground ─────────────────────────────────────────────────────────────

  void _handleForeground(RemoteMessage message) {
    final type = message.data['type'] as String?;
    if (type == null) return;

    // ✅ FIX : lire data['title']/data['body'] d'abord (backend data-only)
    final notification = message.notification;
    final title = (message.data['title'] as String?) ??
        notification?.title ??
        _titleForType(type);
    final body = (message.data['body'] as String?) ??
        notification?.body ??
        _bodyForType(type);

    // ✅ S25 : Déclencher l'alerte sonore + vocale pour les nouvelles missions
    if (type == 'ct_mission_assigned') {
      final missionId = message.data['booking_id'] as String?;
      if (missionId != null) {
        TerrainAlertService.instance.newMission(
          missionId: missionId,
          reference: message.data['reference'] as String?,
          clientName: message.data['client_name'] as String?,
          address: message.data['client_address'] as String?,
          transportMode: message.data['transport_mode'] as String?,
        );
      }
    }

    _showLocalNotification(type: type, title: title, body: body);

    // Snackbar pour les types urgents
    switch (type) {
      case 'booking_confirmed' || 'vehicle_at_center' || 'transport_update' || 'ct_mission_assigned':
        _showSnackbar(
          body,
          action: SnackBarAction(
            label: 'Voir',
            onPressed: () {
              // ✅ S26 : arrêter l'alerte si mission
              if (type == 'ct_mission_assigned') {
                TerrainAlertService.instance.stop();
              }
              final bookingId = message.data['booking_id'] as String?;
              if (type == 'ct_mission_assigned') {
                _navigate('/transport/missions');
              } else if (bookingId != null) {
                _navigate('/booking/$bookingId');
              }
            },
          ),
        );
      case 'vt_reminder_7d' || 'vt_expired':
        _showSnackbar(body);
      default:
        break;
    }
  }

  // ── Tap (background / cold start) ──────────────────────────────────────────

  void _handleTap(RemoteMessage message) {
    final type = message.data['type'] as String?;
    final bookingId = message.data['booking_id'] as String?;

    // ✅ S25 : Arrêter l'alerte si le transporteur tape sur la notif
    if (type == 'ct_mission_assigned') {
      TerrainAlertService.instance.stop();
    }

    switch (type) {
      case 'ct_mission_assigned':
        _navigate('/transport/missions');
      case 'booking_confirmed' || 'vehicle_at_center' || 'transport_update':
        if (bookingId != null) _navigate('/booking/$bookingId');
      default:
        _navigate('/home');
    }
  }

  // ── Notification locale ────────────────────────────────────────────────────

  Future<void> _showLocalNotification({
    required String type,
    required String title,
    required String body,
  }) async {
    try {
      await _localNotifications.show(
        type.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'terrain_alerts',
            'Alertes Terrain CT',
            channelDescription: 'Notifications pour les agents du centre CT',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (_) {}
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnackbar(String text, {SnackBarAction? action}) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  void _navigate(String route) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    Navigator.of(context).pushNamed(route);
  }

  String _titleForType(String type) => switch (type) {
        'booking_confirmed'    => '✅ Nouvelle réservation CT',
        'vehicle_at_center'    => '🏁 Véhicule arrivé au centre',
        'transport_update'     => '🚗 Mise à jour transport',
        'ct_mission_assigned'  => '📋 Nouvelle mission CT assignée',
        'vt_reminder_30d'      => '📅 CT dans 30 jours',
        'vt_reminder_15d'      => '📅 CT dans 15 jours',
        'vt_reminder_7d'       => '⚠️ CT dans 7 jours',
        'vt_expired'           => '🚫 CT expiré',
        _                      => 'VigiRoutes Terrain',
      };

  String _bodyForType(String type) => switch (type) {
        'booking_confirmed'   => 'Une nouvelle réservation a été confirmée.',
        'vehicle_at_center'   => "Le véhicule du client est arrivé. Procédez à l'inspection.",
        'transport_update'    => 'Une mise à jour du transport est disponible.',
        'ct_mission_assigned' => 'Une nouvelle mission de transport vous a été assignée.',
        'vt_reminder_7d'      => 'Rappel : contrôle technique dans 7 jours.',
        'vt_expired'          => 'Contrôle technique expiré — action requise.',
        _                     => 'Appuyez pour voir les détails.',
      };
}