import 'dart:async';
import 'dart:isolate';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/notification_service.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/booking/booking_detail_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

// ── Canal Android notifications terrain ────────────────────────────────────

const AndroidNotificationChannel _terrainChannel = AndroidNotificationChannel(
  'terrain_alerts',
  'Alertes Terrain CT',
  description: 'Notifications pour les agents du centre CT',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

// ── FIX CRITIQUE #1 : stocker le port dans une variable STATIQUE (top-level)
// pour empêcher le garbage collector de le libérer pendant que main() se termine.
// Une variable locale à main() est GC'd immédiatement après la fin de main().
RawReceivePort? _isolateErrorPort;

// ── Handler background / terminated ──────────────────────────────────────
//
// Isolate séparé — affiche une notification locale pour les types importants.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase peut déjà être initialisé dans cet isolate ; on ignore
  // l'exception DuplicateApp plutôt que de crasher.
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  final data = message.data;
  final type = data['type'] as String?;

  const handledTypes = {
    'booking_confirmed',
    'vehicle_at_center',
    'transport_update',
    'vt_reminder_7d',
    'vt_expired',
  };
  if (type == null || !handledTypes.contains(type)) return;

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final notification = message.notification;
  final title = notification?.title ?? _titleForType(type);
  final body  = notification?.body  ?? _bodyForType(type);

  await plugin.show(
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
}

String _titleForType(String type) => switch (type) {
      'booking_confirmed' => '✅ Nouvelle réservation CT',
      'vehicle_at_center' => '🏁 Véhicule arrivé au centre',
      'transport_update'  => '🚗 Mise à jour transport',
      'vt_reminder_7d'    => '⚠️ CT dans 7 jours',
      'vt_expired'        => '🚫 CT expiré',
      _                   => 'VigiRoutes Terrain',
    };

String _bodyForType(String type) => switch (type) {
      'booking_confirmed' => 'Une nouvelle réservation a été confirmée.',
      'vehicle_at_center' => "Le véhicule du client est arrivé. Procédez à l'inspection.",
      'transport_update'  => 'Une mise à jour du transport est disponible.',
      'vt_reminder_7d'    => 'Rappel : contrôle technique dans 7 jours.',
      'vt_expired'        => 'Contrôle technique expiré — action requise.',
      _                   => 'Appuyez pour voir les détails.',
    };

// ── Entrée principale ─────────────────────────────────────────────────────

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Affiche les erreurs UI en rouge en debug pour les diagnostiquer rapidement.
  ErrorWidget.builder = (FlutterErrorDetails details) => Material(
        color: const Color(0xFF8B0000),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            child: Text(
              'ERREUR UI:\n\n${details.exceptionAsString()}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      );

  // ── FIX CRITIQUE #1 : Firebase.initializeApp() peut crasher silencieusement
  // si google-services.json est absent ou mal configuré. On le wrappe pour
  // avoir un message d'erreur explicite.
  try {
    await Firebase.initializeApp();
  } catch (e, s) {
    debugPrint('❌ Firebase.initializeApp() a échoué : $e\n$s');
    // On continue quand même pour afficher l'UI (mode offline).
    runApp(const _FirebaseErrorApp());
    return;
  }

  // ── Crashlytics ──────────────────────────────────────────────────────────
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // FIX CRITIQUE #1 (suite) : _isolateErrorPort est une variable STATIQUE (top-level),
  // pas locale à main(), ce qui empêche le GC de la libérer.
  _isolateErrorPort = RawReceivePort((pair) async {
    final list = pair as List<dynamic>;
    await FirebaseCrashlytics.instance.recordError(
      list.first, list.last as StackTrace?, fatal: true,
    );
  });
  Isolate.current.addErrorListener(_isolateErrorPort!.sendPort);

  // ── FCM background handler ───────────────────────────────────────────────
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ── flutter_local_notifications — canal Android ──────────────────────────
  await _localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      ),
    ),
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_terrainChannel);

  // ── Service notifications foreground ────────────────────────────────────
  // On passe l'instance déjà initialisée au service.
  await TerrainNotificationService.instance.init(_navigatorKey, _localNotifications);

  runApp(const TerrainApp());
}

// ── App de secours si Firebase échoue ────────────────────────────────────

class _FirebaseErrorApp extends StatelessWidget {
  const _FirebaseErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Colors.white54),
                SizedBox(height: 24),
                Text(
                  'Erreur de configuration Firebase',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Vérifiez que google-services.json est bien\nplacé dans android/app/.\n\nContactez le support technique.',
                  style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class TerrainApp extends StatelessWidget {
  const TerrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
      ],
      child: MaterialApp(
        title: 'VigiRoutes Terrain',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
          useMaterial3: true,
        ),
        home: const _RootScreen(),
        routes: {
          '/home': (_) => const HomeScreenWrapper(),
          '/scan': (_) => const ScanScreenWrapper(),
          '/dashboard': (_) => const DashboardScreenWrapper(),
        },
        onGenerateRoute: (settings) {
          if (settings.name?.startsWith('/booking/') == true) {
            final id = settings.name!.replaceFirst('/booking/', '');
            return MaterialPageRoute(
              builder: (_) => BookingDetailScreenWrapper(bookingId: id),
            );
          }
          return null;
        },
      ),
    );
  }
}

// ── FIX #6 : _RootScreen gère TOUTE la navigation post-auth.
// login_screen.dart ne doit plus appeler Navigator.pushReplacementNamed('/home')
// car ça empilerait deux HomeScreenWrapper. _RootScreen est le seul point
// de décision : quand AuthProvider.isAuthenticated passe à true,
// Flutter reconstruit _RootScreen qui retourne HomeScreenWrapper directement.
class _RootScreen extends StatelessWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
      );
    }
    if (auth.isAuthenticated) return const HomeScreenWrapper();
    return const LoginScreen();
  }
}
