import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/settings_model.dart';

class SettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch settings for the current user
  Future<SettingsModel?> fetchSettings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // We use .single() because the DB ensures 1 row per user
      final data = await _supabase
          .from('settings')
          .select()
          .eq('user_id', userId)
          .single();

      return SettingsModel.fromMap(data);
    } catch (e) {
      print("Error fetching settings: $e");
      return null;
    }
  }

  // Update a specific setting (e.g., volume slider changed)
  Future<void> updateSetting(String key, dynamic value) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('settings')
          .update({key: value, 'last_synced_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId);
    } catch (e) {
      print("Error updating setting $key: $e");
    }
  }

  // Update all settings at once
  Future<void> updateAll(SettingsModel settings) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('settings')
          .update(settings.toMap())
          .eq('user_id', userId);
    } catch (e) {
      print("Error syncing settings: $e");
    }
  }
}