import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/theme.dart';
import 'services/ble_service.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'screens/auth/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇👇👇 PASTE YOUR KEYS HERE 👇👇👇
  await Supabase.initialize(
    url: 'https://ekmjqhjjrkbqtkhomksk.supabase.co', // Your Project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrbWpxaGpqcmticXRraG9ta3NrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM5NzUxODAsImV4cCI6MjA3OTU1MTE4MH0.7nR4fXiyGBuko7zDBNjgp5E7fwwI3Ilo1lVEH51TZkE', // Your Anon (Public) Key
  );

  runApp(const SightSyncApp());
}

class SightSyncApp extends StatelessWidget {
  const SightSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BleService>(create: (_) => BleService()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<SettingsService>(create: (_) => SettingsService()),
      ],
      child: MaterialApp(
        title: 'SightSync',
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
