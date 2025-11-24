import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/theme.dart';
import 'services/ble_service.dart';
import 'services/auth_service.dart';
import 'screens/auth/splash_screen.dart';

void main() {
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
      ],
      child: MaterialApp(
        title: 'SightSync',
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(), // Start with Splash
      ),
    );
  }
}
