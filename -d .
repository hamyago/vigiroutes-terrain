import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/booking/booking_detail_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TerrainApp());
}

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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
          useMaterial3: true,
        ),
        home: const _RootScreen(),
        routes: {
          '/home': (_) => const HomeScreenWrapper(),
          '/scan': (_) => const ScanScreen(),
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
