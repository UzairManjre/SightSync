class SettingsModel {
  final int? settingId;
  final String userId;
  final int brightness;
  final int volume;
  final bool voiceControl;
  final String singlePressAction;
  final String doublePressAction;
  final String? wifiSsid;
  final DateTime? lastSyncedAt; // Kept in memory/local only

  SettingsModel({
    this.settingId,
    required this.userId,
    this.brightness = 50,
    this.volume = 50,
    this.voiceControl = true,
    this.singlePressAction = 'describe_scene',
    this.doublePressAction = 'read_text',
    this.wifiSsid,
    this.lastSyncedAt,
  });

  // --- 1. For SUPABASE (Cloud) ---
  // EXCLUDES 'last_synced_at' so we don't mess up the DB
  Map<String, dynamic> toSupabaseJson() {
    return {
      'user_id': userId,
      'brightness': brightness,
      'volume': volume,
      'voice_control_enabled': voiceControl,
      'single_press_action': singlePressAction,
      'double_press_action': doublePressAction,
      'wifi_ssid': wifiSsid,
      // NO last_synced_at here!
    };
  }

  // --- 2. For SQLITE (Local) ---
  // INCLUDES 'last_synced_at' for local history
  Map<String, dynamic> toLocalJson() {
    return {
      'user_id': userId,
      'brightness': brightness,
      'volume': volume,
      'voice_control_enabled': voiceControl ? 1 : 0, // SQLite int boolean
      'single_press_action': singlePressAction,
      'double_press_action': doublePressAction,
      'wifi_ssid': wifiSsid,
      'last_synced_at': lastSyncedAt?.toIso8601String(), // Saved locally
    };
  }

  // --- Factory (Works for both) ---
  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      settingId: map['setting_id'],
      userId: map['user_id'] ?? '',
      brightness: map['brightness'] ?? 50,
      volume: map['volume'] ?? 50,
      // Handle both Boolean (Supabase) and Int (SQLite) logic
      voiceControl: map['voice_control_enabled'] == true || map['voice_control_enabled'] == 1,
      singlePressAction: map['single_press_action'] ?? 'describe_scene',
      doublePressAction: map['double_press_action'] ?? 'read_text',
      wifiSsid: map['wifi_ssid'],
      lastSyncedAt: map['last_synced_at'] != null
          ? DateTime.parse(map['last_synced_at'])
          : null,
    );
  }

  // Helper to create a copy with updated time
  SettingsModel copyWith({DateTime? lastSyncedAt}) {
    return SettingsModel(
      settingId: settingId,
      userId: userId,
      brightness: brightness,
      volume: volume,
      voiceControl: voiceControl,
      singlePressAction: singlePressAction,
      doublePressAction: doublePressAction,
      wifiSsid: wifiSsid,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}