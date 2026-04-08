import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';


class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  String _geminiApiKey = '';

  String get geminiApiKey => _geminiApiKey;

  Future<void> init() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Set defaults in case the fetch fails or there is no network
      await remoteConfig.setDefaults(const {
        'gemini_api_key': '',
      });

      // Quick fetch intervals for development/beta
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5), // Change to hours in prod
      ));

      await remoteConfig.fetchAndActivate();

      _geminiApiKey = remoteConfig.getString('gemini_api_key');

      if (_geminiApiKey.isEmpty) {
        debugPrint('[REMOTE CONFIG] Warning: gemini_api_key is empty in Firebase.');
      } else {
        debugPrint('[REMOTE CONFIG] Successfully fetched Gemini API Key.');
      }
    } catch (e) {
      debugPrint('[REMOTE CONFIG] Error initializing: $e');
    }
  }
}
