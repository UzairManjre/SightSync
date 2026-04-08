import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'utils/theme.dart';
import 'services/ble_service.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'services/ai_service.dart';
import 'services/remote_config_service.dart';
import 'screens/auth/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize AI engine (sets TTS language/rate) before UI renders
  await AiService().init();
  await RemoteConfigService().init();


  runApp(const SightSyncApp());
}

class SightSyncApp extends StatelessWidget {
  const SightSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BleService>(create: (_) => BleService()),
        ChangeNotifierProvider<AiService>(create: (_) => AiService()),
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
