import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'providers/router_provider_extended.dart';
import 'providers/settings_provider.dart';
import 'services/database_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/router_selection_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/bandwidth_control_screen.dart';
import 'screens/parental_control_screen.dart';
import 'screens/settings_screen_extended.dart';
import 'utils/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize secure storage
  await SecureStorage.init();

  // Initialize database
  await DatabaseService().database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExtendedRouterProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Huawei Router Manager',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              brightness: Brightness.light,
              fontFamily: 'Roboto',
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              brightness: Brightness.dark,
              fontFamily: 'Roboto',
            ),
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/routers': (context) => const RouterSelectionScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/bandwidth': (context) => const BandwidthControlScreen(),
              '/parental': (context) => const ParentalControlScreen(),
              '/settings': (context) => const ExtendedSettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
