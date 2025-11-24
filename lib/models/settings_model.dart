class SettingsModel {
  final int? settingId;
  final int userId;
  int brightness;
  int volume;
  bool voiceControl;
  String singlePressMap;
  String doublePressMap;
  String? wifiSsid;

  SettingsModel({
    this.settingId,
    required this.userId,
    this.brightness = 50,
    this.volume = 50,
    this.voiceControl = true,
    this.singlePressMap = 'scene_desc',
    this.doublePressMap = 'ocr',
    this.wifiSsid,
  });

  Map<String, dynamic> toMap() {
    return {
      'setting_id': settingId,
      'user_id': userId,
      'brightness': brightness,
      'volume': volume,
      'voice_control': voiceControl ? 1 : 0, // SQLite stores booleans as 0/1
      'single_press_map': singlePressMap,
      'double_press_map': doublePressMap,
      'wifi_ssid': wifiSsid,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      settingId: map['setting_id'],
      userId: map['user_id'],
      brightness: map['brightness'],
      volume: map['volume'],
      voiceControl: map['voice_control'] == 1,
      singlePressMap: map['single_press_map'],
      doublePressMap: map['double_press_map'],
      wifiSsid: map['wifi_ssid'],
    );
  }

  @override
  String toString() {
    return 'SettingsModel{settingId: $settingId, userId: $userId, brightness: $brightness, volume: $volume, voiceControl: $voiceControl, singlePressMap: $singlePressMap, doublePressMap: $doublePressMap, wifiSsid: $wifiSsid}';
  }
}
