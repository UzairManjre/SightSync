import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/settings_model.dart';
import 'database_helper.dart';

class SettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseHelper _localDb = DatabaseHelper();

  // Fetch settings (Cloud + Local Merge)
  Future<SettingsModel?> fetchSettings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    SettingsModel? cloudSettings;
    SettingsModel? localSettings;

    // 1. Try Local Load
    try {
      localSettings = await _localDb.getSettings(userId);
    } catch (e) {
      print("Local DB skipped (Web or Error)");
    }

    try {
      // 2. Try Cloud Load
      final data = await _supabase
          .from('settings')
          .select()
          .eq('user_id', userId)
          .single();
      cloudSettings = SettingsModel.fromMap(data);
      
      // 3. Merge & Save
      final mergedSettings = cloudSettings.copyWith(
        lastSyncedAt: localSettings?.lastSyncedAt 
      );
      
      // Safely attempt local save
      await _localDb.insertSettings(mergedSettings);
      return mergedSettings;

    } catch (e) {
      print("Cloud fetch failed: $e");
      return localSettings;
    }
  }

  // Update specific setting
  Future<void> updateSetting(String key, dynamic value) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('settings')
          .update({key: value})
          .eq('user_id', userId);
          
      // Update Local Timestamp
      final local = await _localDb.getSettings(userId);
      // If local is null (Web), create a temporary object just to proceed logic if needed
      // or just skip.
      if (local != null) {
        await _localDb.insertSettings(
          local.copyWith(lastSyncedAt: DateTime.now())
        );
      }
    } catch (e) {
      print("Error updating setting $key: $e");
      rethrow;
    }
  }
  
  Future<void> performManualSync() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final local = await _localDb.getSettings(userId);
    if (local != null) {
      await _localDb.insertSettings(
        local.copyWith(lastSyncedAt: DateTime.now())
      );
    }
  }
}