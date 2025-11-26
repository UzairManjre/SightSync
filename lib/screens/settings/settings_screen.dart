import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ble_service.dart';
import '../../services/auth_service.dart';
import '../auth/splash_screen.dart';
import '../../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _brightness = 50;
  double _volume = 50;
  String _singlePressAction = 'scene_desc';
  String _doublePressAction = 'ocr';

  @override
  Widget build(BuildContext context) {
    final bleService = context.watch<BleService>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Settings",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 10),
                  
                  // Profile Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPurple,
                          AppColors.primaryBlue,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: const Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Test User",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "test@example.com",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Device Controls Section
                  const Text(
                    "Device Controls",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildControlCard(
                    icon: Icons.brightness_6,
                    title: "Brightness",
                    subtitle: "Adjust IR LED brightness",
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: AppColors.primaryPurple,
                                  inactiveTrackColor: AppColors.primaryPurple.withOpacity(0.2),
                                  thumbColor: AppColors.primaryPurple,
                                  overlayColor: AppColors.primaryPurple.withOpacity(0.2),
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  value: _brightness,
                                  min: 0,
                                  max: 100,
                                  onChanged: (val) {
                                    setState(() => _brightness = val);
                                    _sendConfig(bleService, "brightness", val.toInt());
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "${_brightness.round()}%",
                              style: const TextStyle(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildControlCard(
                    icon: Icons.volume_up,
                    title: "Volume",
                    subtitle: "Bone conduction speaker volume",
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: AppColors.primaryPurple,
                                  inactiveTrackColor: AppColors.primaryPurple.withOpacity(0.2),
                                  thumbColor: AppColors.primaryPurple,
                                  overlayColor: AppColors.primaryPurple.withOpacity(0.2),
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  value: _volume,
                                  min: 0,
                                  max: 100,
                                  onChanged: (val) {
                                    setState(() => _volume = val);
                                    _sendConfig(bleService, "volume", val.toInt());
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "${_volume.round()}%",
                              style: const TextStyle(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Button Mapping Section
                  const Text(
                    "Button Mapping",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDropdownCard(
                    icon: Icons.touch_app,
                    title: "Single Press",
                    value: _singlePressAction,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _singlePressAction = val);
                        _sendConfig(bleService, "single_press_map", val);
                      }
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildDropdownCard(
                    icon: Icons.double_arrow,
                    title: "Double Press",
                    value: _doublePressAction,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _doublePressAction = val);
                        _sendConfig(bleService, "double_press_map", val);
                      }
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Other Settings
                  const Text(
                    "General",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildMenuCard(
                    icon: Icons.notifications_outlined,
                    title: "Notifications",
                    onTap: () {},
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildMenuCard(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    onTap: () {},
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildMenuCard(
                    icon: Icons.info_outline,
                    title: "About",
                    onTap: () {},
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildMenuCard(
                    icon: Icons.logout,
                    title: "Disconnect Device",
                    isDestructive: true,
                    onTap: () async {
                      await bleService.disconnect();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  
                  const SizedBox(height: 12),

                  _buildMenuCard(
                    icon: Icons.exit_to_app,
                    title: "Logout",
                    isDestructive: true,
                    onTap: () async {
                      final authService = context.read<AuthService>();
                      await authService.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const SplashScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryPurple, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdownCard({
    required IconData icon,
    required String title,
    required String value,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: AppColors.cardBackground,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    items: const [
                      DropdownMenuItem(value: 'scene_desc', child: Text("Describe Scene")),
                      DropdownMenuItem(value: 'ocr', child: Text("Read Text (OCR)")),
                      DropdownMenuItem(value: 'nav', child: Text("Navigation")),
                      DropdownMenuItem(value: 'voice', child: Text("Voice Assistant")),
                    ],
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.error.withOpacity(0.2)
                    : AppColors.primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.error : AppColors.primaryPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _sendConfig(BleService service, String key, dynamic value) {
    try {
      service.writeCommand({
        "cmd": "set_config",
        "key": key,
        "value": value,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update settings: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
