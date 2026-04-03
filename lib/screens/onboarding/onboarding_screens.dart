import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:math' as math;
import '../../services/ble_service.dart';
import '../../utils/theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../../widgets/ambient_background.dart';
import 'user_guide_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
///  ONBOARDING CONTROLLER
/// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  final int initialPage;
  const OnboardingScreen({super.key, this.initialPage = 0});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pc;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController(initialPage: widget.initialPage);
    _page = widget.initialPage;
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pc.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        useImage: true,
        child: Stack(
          children: [
            PageView(
              controller: _pc,
              onPageChanged: (i) => setState(() => _page = i),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _WelcomePage(onNext: _next),
                _DeviceSelectionPage(onNext: _next),
                const UserGuideScreen(),
              ],
            ),

            // Page dots
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i ? AppColors.primary : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
///  PAGE 1 — Welcome / Ready to guide you
/// ─────────────────────────────────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Illustration placeholder — eye icon in a glowing circle
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: const Icon(Icons.remove_red_eye_outlined, size: 48, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 48),

            const Text(
              "You're all set,\nwe're ready to\nguide you.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -1.5,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SightSync uses AI and wearable sensors to help you understand the world.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            ),

            const Spacer(),

            // Next button
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.06),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                child: const Text('Pair my device', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 40), // Spacing for dots
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
///  PAGE 2 — Device Selection (BLE list)
/// ─────────────────────────────────────────────────────────────────────────────
class _DeviceSelectionPage extends StatefulWidget {
  final VoidCallback onNext;
  const _DeviceSelectionPage({required this.onNext});

  @override
  State<_DeviceSelectionPage> createState() => _DeviceSelectionPageState();
}

class _DeviceSelectionPageState extends State<_DeviceSelectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ble = context.read<BleService>();
      await ble.init();
      ble.startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select your\ndevice',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -1.2,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ensure your SightSync module is nearby.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Scanning indicator
            Row(
              children: [
                const SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  'SCANNING...',
                  style: TextStyle(color: AppColors.primary.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Device list
            Expanded(
              child: StreamBuilder<List<ScanResult>>(
                stream: ble.scanResults,
                builder: (context, snap) {
                  final results = (snap.data ?? []).where((r) {
                    final name = r.device.platformName.toLowerCase();
                    return name.contains('sightsync');
                  }).toList();

                  if (results.isEmpty) {
                    return Center(
                      child: Text('SEARCHING...',
                          style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 13, letterSpacing: 3, fontWeight: FontWeight.bold)),
                    );
                  }
                  return ListView.separated(
                    itemCount: results.length,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final r = results[i];
                      final name = r.device.platformName.isNotEmpty ? r.device.platformName : 'SIGHTSYNC_NODE';
                      return _DeviceListTile(
                        name: name,
                        onTap: () async {
                          final pin = (100000 + math.Random().nextInt(899999)).toString();
                          
                          // 1. Start connecting
                          try {
                            // Show a quick snackbar or just wait (ux is better if we go to a connecting screen)
                            await ble.connectLeft(r.device);
                            
                            // 2. Once connected, send PIN to the chip
                            await ble.writeCommand({'type': 'pairing_pin', 'pin': pin});

                            if (!mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PairingCodePage(
                                  deviceName: name,
                                  pin: pin,
                                  onConfirm: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const UserGuideScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to connect: $e'))
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: widget.onNext,
                child: const Text(
                  'Skip for now',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40), // Spacing for dots
          ],
        ),
      ),
    );
  }
}

class _DeviceListTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _DeviceListTile({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.bluetooth, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
///  PAIRING CODE PAGE
/// ─────────────────────────────────────────────────────────────────────────────
class PairingCodePage extends StatefulWidget {
  final String deviceName;
  final String pin;
  final VoidCallback onConfirm;
  const PairingCodePage({required this.deviceName, required this.pin, required this.onConfirm});

  @override
  State<PairingCodePage> createState() => PairingCodePageState();
}

class PairingCodePageState extends State<PairingCodePage> {
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        useImage: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                    child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Confirm PIN',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, fontFamily: 'SpaceGrotesk'),
                ),
                const SizedBox(height: 12),
                Text('Pairing with ${widget.deviceName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 48),

                // PIN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.pin.split('').map((d) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 44, height: 60,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
                      child: Center(child: Text(d, style: const TextStyle(color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.w800))),
                    );
                  }).toList(),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _isConnecting ? null : () async {
                      setState(() => _isConnecting = true);
                      await Future.delayed(const Duration(seconds: 2));
                      if (mounted) {
                        Navigator.of(context).pop();
                        widget.onConfirm();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.06),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    child: _isConnecting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('CONFIRM'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
///  PAGE 3 — Button Mapping Tutorial
/// ─────────────────────────────────────────────────────────────────────────────
class _ButtonMappingPage extends StatelessWidget {
  const _ButtonMappingPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to use',
              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, fontFamily: 'SpaceGrotesk'),
            ),
            const SizedBox(height: 12),
            const Text('Your module has two smart buttons.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 40),

            _MappingRow(icon: Icons.touch_app_outlined, title: 'Short Press', description: 'Read text and signs.'),
            const SizedBox(height: 16),
            _MappingRow(icon: Icons.touch_app, title: 'Long Press', description: 'Describe surroundings.'),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    (r) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                child: const Text("LET'S GO", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 40), // Spacing for dots
          ],
        ),
      ),
    );
  }
}

class _MappingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _MappingRow({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
