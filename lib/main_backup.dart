import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/theme.dart';
import 'services/ble_service.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'screens/auth/splash_screen.dart';

import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with a timeout to prevent startup hangs
  try {
    await Supabase.initialize(
      url: 'https://ekmjqhjjrkbqtkhomksk.supabase.co',
      anonKey: 'sb_publishable_ZPO2ua0zIKhPZ_4ZwJdwMQ_QUJJ1hT7',
    ).timeout(const Duration(seconds: 5), onTimeout: () {
      debugPrint('Supabase initialization timed out');
      return Supabase.instance; // Proceed with partially initialized or existing instance
    });
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  runApp(const SightSyncApp());
}

class SightSyncApp extends StatelessWidget {
  const SightSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Basic error boundary
    ErrorWidget.builder = (details) => Container(
      color: const Color(0xFF0F0F1E),
      child: Center(
        child: Text(
          'Initialization Error: ${details.exception}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );

    return MultiProvider(
      providers: [
        Provider<BleService>(create: (_) => BleService()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<SettingsService>(create: (_) => SettingsService()),
      ],
      child: MaterialApp(
        title: 'SightSync',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
