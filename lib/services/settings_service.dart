import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/settings_model.dart';
import 'database_helper.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _localDb = DatabaseHelper();

  String? get _userId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _firestore.collection('users').doc(_userId).collection('data').doc('settings');

  // Fetch settings (Cloud + Local Merge)
  Future<SettingsModel?> fetchSettings() async {
    final userId = _userId;
    if (userId == null) return null;

    SettingsModel? localSettings;

    // 1. Try local cache first
    try {
      localSettings = await _localDb.getSettings(userId);
    } catch (_) {}

    try {
      // 2. Try Firestore
      final snap = await _settingsDoc.get();
      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        data['user_id'] = userId; // Inject for model
        final cloudSettings = SettingsModel.fromMap(data);
        final merged = cloudSettings.copyWith(
            lastSyncedAt: localSettings?.lastSyncedAt);
        await _localDb.insertSettings(merged);
        return merged;
      }
    } catch (e) {
      // Cloud failed — fall back to local
      return localSettings;
    }

    // 3. No cloud data — create defaults
    final defaults = SettingsModel(userId: userId);
    await _settingsDoc.set(defaults.toFirestoreJson());
    await _localDb.insertSettings(defaults);
    return defaults;
  }

  // Update a specific setting key
  Future<void> updateSetting(String key, dynamic value) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _settingsDoc.update({key: value});
      final local = await _localDb.getSettings(userId);
      if (local != null) {
        await _localDb
            .insertSettings(local.copyWith(lastSyncedAt: DateTime.now()));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> performManualSync() async {
    final userId = _userId;
    if (userId == null) return;
    final local = await _localDb.getSettings(userId);
    if (local != null) {
      await _localDb
          .insertSettings(local.copyWith(lastSyncedAt: DateTime.now()));
    }
  }
}