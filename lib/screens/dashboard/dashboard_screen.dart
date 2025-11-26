import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ble_service.dart';
import '../../services/settings_service.dart'; // Added for Last Synced logic
import '../../utils/theme.dart';
import '../settings/settings_screen.dart';
import '../../widgets/floating_nav_bar.dart';
import 'controls_screen.dart';
import 'guide_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // UI State
  String _userName = "User";
  int _batteryLevel = 0;
  String _lastSyncedText = "Never";
  bool _isSyncing = false;
  bool _isListening = false;
  bool _isLoadingControls = true;
  String _singlePressAction = 'describe_scene';
  String _doublePressAction = 'read_text';
  String _longPressAction = 'off';

  // Navigation State
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _initDashboardData();
  }

  void _initDashboardData() {
    _fetchUserProfile();
    _fetchLastSyncedTime(); // Get initial sync time from DB
    _loadControlSettings();
    _setupBleListeners();
  }

  Future<void> _loadControlSettings() async {
    final settingsService = context.read<SettingsService>();
    final settings = await settingsService.fetchSettings();
    
    if (mounted) {
      if (settings != null) {
        setState(() {
          _singlePressAction = settings.singlePressAction;
          _doublePressAction = settings.doublePressAction;
          _isLoadingControls = false;
        });
      } else {
        setState(() => _isLoadingControls = false);
      }
    }
  }

  Future<void> _updateControlMapping(String key, String value) async {
    // A. Update UI immediately (Optimistic UI)
    setState(() {
      if (key == 'single_press_action') _singlePressAction = value;
      if (key == 'double_press_action') _doublePressAction = value;
      if (key == 'long_press_action') _longPressAction = value;
    });

    final settingsService = context.read<SettingsService>();
    final bleService = context.read<BleService>();
    
    try {
      // B. Update Database (Cloud + Local)
      await settingsService.updateSetting(key, value);

      // C. Send BLE Command to ESP32
      if (bleService.connectedDevice != null) {
        // Protocol: {"cmd": "set_config", "key": "single_press", "val": "ocr"}
        await bleService.writeCommand({
          "cmd": "set_config",
          "key": key,
          "value": value
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Glasses updated: ${key.replaceAll('_', ' ')} -> $value"),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      // Revert UI if needed in production
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 1. Fetch User Name
  void _fetchUserProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.userMetadata?['full_name']?.split(' ').first ?? "User";
      });
    }
  }

  // 2. Fetch Last Synced Time from Supabase
  Future<void> _fetchLastSyncedTime() async {
    final settingsService = context.read<SettingsService>();
    final settings = await settingsService.fetchSettings();

    if (settings?.lastSyncedAt != null && mounted) {
      setState(() {
        _lastSyncedText = _formatTimeAgo(settings!.lastSyncedAt!);
      });
    }
  }

  // 3. Manual Sync Action
  Future<void> _performManualSync() async {
    setState(() => _isSyncing = true);

    try {
      // This now pulls fresh data from cloud AND updates local timestamp
      await context.read<SettingsService>().fetchSettings();

      // Explicitly mark sync as done locally
      await context.read<SettingsService>().performManualSync();

      await _fetchLastSyncedTime(); // Refresh UI text

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sync Complete"),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sync Failed"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // 4. BLE Listeners (Battery & Thermal)
  void _setupBleListeners() {
    final bleService = context.read<BleService>();

    // Safety Alert
    bleService.eventStream.listen((event) {
      if (event == "Thermal Warning" && mounted) {
        _showThermalAlert();
      }
    });

    // Real Battery Updates
    bleService.batteryStream.listen((level) {
      if (mounted) {
        setState(() => _batteryLevel = level);
      }
    });
  }

  // --- UI HELPERS ---

  void _showThermalAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Row(
          children: [Icon(Icons.warning_amber_rounded, color: AppColors.error), SizedBox(width: 10), Text("Overheating")],
        ),
        content: const Text("Night Vision disabled due to high temperature."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Dismiss"))],
      ),
    );
  }

  void _toggleListeningMode() {
    final isConnected = context.read<BleService>().connectedDevice != null;
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connect glasses first."), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isListening = !_isListening);
  }

  void _handleNavTap(int index) {
    if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    } else {
      setState(() => _currentNavIndex = index);
      _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  // Simple Time Ago Formatter (No extra package needed)
  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return "${diff.inDays} days ago";
    if (diff.inHours > 0) return "${diff.inHours} hours ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes} mins ago";
    return "Just now";
  }

  @override
  Widget build(BuildContext context) {
    final bleService = context.watch<BleService>();
    final isConnected = bleService.connectedDevice != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // 1. Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF050510), Color(0xFF0A1A35), Color(0xFF4E73DF)],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // 2. Content
          SafeArea(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  if (index != 3) _currentNavIndex = index;
                });
              },
              children: [
                _buildMainDashboardPage(isConnected), // Page 0
                
                ControlsScreen(
                  isListening: _isListening,
                  onToggleListening: _toggleListeningMode,
                  isLoading: _isLoadingControls,
                  singlePressAction: _singlePressAction,
                  doublePressAction: _doublePressAction,
                  longPressAction: _longPressAction,
                  onUpdateMapping: _updateControlMapping,
                ),
                
                const GuideScreen(), // Page 2
                
                _buildPlaceholderPage("Settings", Icons.settings),
              ],
            ),
          ),

          // 3. Page Indicator
          Positioned(
            bottom: 110,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => _buildPageIndicator(index)),
            ),
          ),

          // 4. Floating Nav Bar
          FloatingNavBar(
            currentIndex: _currentNavIndex,
            onTap: _handleNavTap,
          ),
        ],
      ),
    );
  }

  Widget _buildMainDashboardPage(bool isConnected) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Wave Icon
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _toggleListeningMode,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _isListening ? AppColors.success : Colors.white24, width: 2),
                  color: _isListening ? AppColors.success.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  boxShadow: _isListening ? [BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 15)] : [],
                ),
                child: Icon(_isListening ? Icons.mic : Icons.graphic_eq, color: _isListening ? AppColors.success : Colors.white, size: 24),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Header
          const Text("Device", style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            "$_userName's SightSync",
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w400),
          ),

          const SizedBox(height: 60),

          // --- REAL STATUS CARDS ---

          // Connection
          _buildStatusCard(
            child: Row(
              children: [
                _buildStatusDot(isConnected),
                const SizedBox(width: 16),
                const Text("Connection Status", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const Spacer(),
                Text(isConnected ? "Connected" : "Disconnected", style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Battery (REAL DATA)
          _buildStatusCard(
            child: Row(
              children: [
                const Text("Battery", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(width: 12),
                const Text("-", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(width: 12),
                Text(
                  isConnected ? "$_batteryLevel%" : "--",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                SizedBox(
                  width: 100,
                  height: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: isConnected ? (_batteryLevel / 100) : 0,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(_getBatteryColor(_batteryLevel)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sync (REAL DATA)
          _buildStatusCard(
            child: Row(
              children: [
                const Text("Last Synced", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(width: 12),
                const Text("-", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(width: 12),
                Text(_lastSyncedText, style: const TextStyle(color: Colors.white, fontSize: 16)),
                const Spacer(),
                // Sync Button
                GestureDetector(
                  onTap: _isSyncing || !isConnected ? null : _performManualSync,
                  child: _isSyncing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(Icons.refresh, color: isConnected ? Colors.white : Colors.white24, size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ... Keep helpers (_buildPlaceholderPage, _getBatteryColor, _buildStatusCard, _buildStatusDot, _buildPageIndicator) same as previous ...
  Widget _buildPlaceholderPage(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white24),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Feature coming soon", style: TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return AppColors.success;
    if (level > 20) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildStatusCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A182E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.15), width: 1),
      ),
      child: child,
    );
  }

  Widget _buildStatusDot(bool active) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
          color: active ? AppColors.success : AppColors.error,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: (active ? AppColors.success : AppColors.error).withOpacity(0.6), blurRadius: 6)]
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 20,
      height: 4,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white24,
        borderRadius: BorderRadius.circular(2),
        boxShadow: isActive ? [const BoxShadow(color: Colors.white54, blurRadius: 4)] : [],
      ),
    );
  }
}