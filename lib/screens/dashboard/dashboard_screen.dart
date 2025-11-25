import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ble_service.dart';
import '../../utils/theme.dart';
import '../settings/settings_screen.dart';
// Import the new reusable widget
import '../../widgets/floating_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = "User";
  int _batteryLevel = 0;

  // Dashboard is index 0
  final int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _setupBleListeners();
  }

  void _fetchUserProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.userMetadata?['full_name']?.split(' ').first ?? "User";
      });
    }
  }

  void _setupBleListeners() {
    final bleService = context.read<BleService>();

    bleService.eventStream.listen((event) {
      if (event == "Thermal Warning" && mounted) {
        // Thermal Alert Logic
      }
    });

    bleService.batteryStream.listen((level) {
      if (mounted) setState(() => _batteryLevel = level);
    });
  }

  void _handleNavTap(int index) {
    if (index == _currentIndex) return; // Already on this page

    // Navigation Logic
    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        // Navigate to Controls
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ControlsScreen()));
        break;
      case 2:
        // Navigate to Guide
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GuideScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleService = context.watch<BleService>();
    final isConnected = bleService.connectedDevice != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // --- LAYER 1: BACKGROUND GRADIENT ---
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF050510), // Deep dark at top
                  Color(0xFF0A1A35), // Mid blue
                  Color(0xFF4E73DF), // Lighter blue at bottom (Horizon effect)
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // --- LAYER 2: SCROLLABLE CONTENT ---
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Wave Icon
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                              color: Colors.white.withOpacity(0.05),
                            ),
                            child: const Icon(Icons.graphic_eq, color: Colors.white, size: 24),
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

                        // Cards
                        _buildStatusCard(
                          child: Row(
                            children: [
                              _buildStatusDot(isConnected),
                              const SizedBox(width: 16),
                              const Text("Connection Status", style: TextStyle(color: Colors.white70, fontSize: 16)),
                              const Spacer(),
                              Text(
                                isConnected ? "Connected" : "Disconnected",
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Battery
                        _buildStatusCard(
                          child: Row(
                            children: [
                              const Text("Battery", style: TextStyle(color: Colors.white70, fontSize: 16)),
                              const SizedBox(width: 12),
                              const Text("-", style: TextStyle(color: Colors.white70, fontSize: 16)),
                              const SizedBox(width: 12),
                              Text(
                                isConnected ? "$_batteryLevel%" : "85%", // Mock 85% if disconnected for UI check
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 100,
                                height: 12,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: 0.85,
                                    backgroundColor: Colors.white10,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sync
                        _buildStatusCard(
                          child: Row(
                            children: [
                              const Text("Last Synced", style: TextStyle(color: Colors.white70, fontSize: 16)),
                              const SizedBox(width: 12),
                              const Text("-", style: TextStyle(color: Colors.white70, fontSize: 16)),
                              const SizedBox(width: 12),
                              const Text("5 mins ago", style: TextStyle(color: Colors.white, fontSize: 16)),
                              const Spacer(),
                              const Icon(Icons.refresh, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- LAYER 3: PAGE INDICATOR ---
          Positioned(
            bottom: 110, // Positioned just above the floating nav bar
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPageIndicator(true),
                _buildPageIndicator(false),
                _buildPageIndicator(false),
                _buildPageIndicator(false),
              ],
            ),
          ),

          // --- LAYER 4: REUSABLE FLOATING NAV BAR ---
          FloatingNavBar(
            currentIndex: _currentIndex,
            onTap: _handleNavTap,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A182E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.15),
          width: 1,
        ),
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
        boxShadow: [
          BoxShadow(
            color: (active ? AppColors.success : AppColors.error).withOpacity(0.6),
            blurRadius: 6,
          )
        ]
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 20,
      height: 4,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
