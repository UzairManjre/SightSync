// lib/screens/onboarding/onboarding_screens.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../services/ble_service.dart';
import '../../utils/theme.dart';
import '../dashboard/dashboard_screen.dart';

const String backgroundImageUrl = '/mnt/data/6c49ffa0-be1d-4a9b-9c13-264460091105.png';
const String glassesImageUrl = '/mnt/data/93a24752-c1a5-4f28-8408-48b61dc2eb01.png';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void goToNextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Full-bleed background image (use your pipeline to transform the path into a URL)
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              backgroundImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.backgroundDark),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    physics: const NeverScrollableScrollPhysics(), // user must use slider to move
                    children: [
                      DesignerIntroPage(onSlideComplete: goToNextPage),
                      DesignerConnectPage(),
                      DesignerButtonTutorialPage(),
                    ],
                  ),
                ),
                // Page indicators
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: _currentPage == index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(_currentPage == index ? 0.95 : 0.22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A draggable slide-to-advance control.
/// When user slides knob past 80% it calls onSlideComplete.
class SlideToAdvance extends StatefulWidget {
  final VoidCallback onSlideComplete;
  final String label;
  const SlideToAdvance({required this.onSlideComplete, required this.label, super.key});

  @override
  State<SlideToAdvance> createState() => _SlideToAdvanceState();
}

class _SlideToAdvanceState extends State<SlideToAdvance> with SingleTickerProviderStateMixin {
  double _dx = 0;
  bool _completed = false;
  late double _maxDx;
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dx = (_dx + d.delta.dx).clamp(0.0, _maxDx);
    });
  }

  void _onDragEnd(DragEndDetails _) {
    // Threshold 80% of available space
    if (_dx >= _maxDx * 0.8 && !_completed) {
      setState(() => _completed = true);
      widget.onSlideComplete();
      // animate knob all the way to end
      setState(() => _dx = _maxDx);
    } else {
      // snap back
      setState(() => _dx = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final fullW = constraints.maxWidth;
      final knobSize = 56.0;
      _maxDx = max(0, fullW - knobSize - 8);

      return SizedBox(
        height: 64,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
                color: Colors.white.withOpacity(0.03),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
                ],
              ),
            ),
            Positioned(
              left: 4 + _dx,
              child: GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: Container(
                  width: knobSize,
                  height: knobSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.98),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6)],
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class DesignerIntroPage extends StatelessWidget {
  final VoidCallback onSlideComplete;
  const DesignerIntroPage({required this.onSlideComplete, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            'SightSync is ready\nto guide you',
            style: TextStyle(
              color: Colors.white,
              fontSize: 44,
              height: 1.05,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Follow the on-screen steps or use voice guidance\nto complete your setup.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.6),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Center(child: Icon(Icons.graphic_eq, color: Colors.white.withOpacity(0.9))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SlideToAdvance(onSlideComplete: onSlideComplete, label: 'Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DesignerConnectPage extends StatefulWidget {
  const DesignerConnectPage({super.key});
  @override
  State<DesignerConnectPage> createState() => _DesignerConnectPageState();
}

class _DesignerConnectPageState extends State<DesignerConnectPage> {
  @override
  void initState() {
    super.initState();
    // Start scanning once this page builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BleService>().startScan();
    });
  }

  Future<void> _onDeviceTap(BuildContext context, ScanResult r) async {
    final bleService = context.read<BleService>();
    final deviceName = r.device.platformName.isNotEmpty
        ? r.device.platformName
        : (r.device.name.isNotEmpty ? r.device.name : 'Unknown Device');

    // Show connecting dialog (non-dismissable)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.95))),
              const SizedBox(height: 12),
              Text('Connecting to $deviceName...', style: TextStyle(color: Colors.white.withOpacity(0.9))),
            ],
          ),
        ),
      ),
    );

    try {
      // Attempt connection
      await bleService.stopScan();
      await bleService.connect(r.device);

      // After successful connection, pop the dialog and push pairing page
      if (context.mounted) {
        Navigator.of(context).pop(); // pop connecting dialog
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PairingConfirmPage(deviceName: deviceName)),
        );
      }
    } catch (e) {
      // connection failed
      if (context.mounted) {
        Navigator.of(context).pop(); // pop connecting dialog
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: Text('Connection Failed', style: TextStyle(color: Colors.white)),
            content: Text('Could not connect to $deviceName. Try again.', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleService = context.watch<BleService>();

    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = constraints.maxWidth * 0.85;
      final cardHeight = constraints.maxHeight * 0.55;

      return Column(
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(cardWidth * 0.5),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white.withOpacity(0.02), Colors.black.withOpacity(0.18)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bluetooth, size: 72, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(height: 18),
                  Text('Make sure Bluetooth is turned on', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  const SizedBox(height: 12),
                  Container(width: cardWidth * 0.6, height: 1, color: Colors.white.withOpacity(0.06)),
                  const SizedBox(height: 14),
                  Text('Select your device', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<List<ScanResult>>(
                      stream: bleService.scanResults,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('Searching for devices...', style: TextStyle(color: Colors.white.withOpacity(0.7))));
                        }
                        final results = snapshot.data!;
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (ctx, i) {
                            final r = results[i];
                            final deviceName = r.device.platformName.isNotEmpty ? r.device.platformName : (r.device.name.isNotEmpty ? r.device.name : 'Unknown Device');
                            return GestureDetector(
                              onTap: () => _onDeviceTap(context, r),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.devices, color: Colors.white.withOpacity(0.9)),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(deviceName, style: TextStyle(color: Colors.white.withOpacity(0.95)))),
                                    Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.28)),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: Center(child: Icon(Icons.graphic_eq, color: Colors.white.withOpacity(0.9)))),
              const SizedBox(height: 10),
              Text('Voice guidance enabled', style: TextStyle(color: Colors.white.withOpacity(0.9))),
            ],
          ),
          const Spacer(),
        ],
      );
    });
  }
}

/// Page displayed once the BLE connect attempt is successful.
/// Contains pairing code UI and Continue button (Continue enabled only when bleService confirms connected).
class PairingConfirmPage extends StatefulWidget {
  final String deviceName;
  const PairingConfirmPage({required this.deviceName, super.key});

  @override
  State<PairingConfirmPage> createState() => _PairingConfirmPageState();
}

class _PairingConfirmPageState extends State<PairingConfirmPage> {
  // Example hard-coded code — in real life you'd get actual pairing code or show instructions
  final List<String> _codeDigits = ['6', '6', '8', '0', '0', '1'];

  @override
  Widget build(BuildContext context) {
    final bleService = context.watch<BleService>();
    final connected = bleService.connectedDevice != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: Image.network(backgroundImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.backgroundDark))),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.height * 0.55,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(300),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 12),
                          Icon(Icons.bluetooth, size: 64, color: Colors.white.withOpacity(0.9)),
                          const SizedBox(height: 12),
                          Text(widget.deviceName, style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 16)),
                          const SizedBox(height: 12),
                          Container(height: 1, width: double.infinity, color: Colors.white.withOpacity(0.04)),
                          const SizedBox(height: 12),
                          Text('Confirm the pairing code.', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _codeDigits.map((d) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                width: 46,
                                height: 58,
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                                child: Center(child: Text(d, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600))),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: 140,
                            child: OutlinedButton(
                              onPressed: connected
                                  ? () {
                                // Only navigate to dashboard when connection is confirmed
                                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen()));
                              }
                                  : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withOpacity(0.18)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                backgroundColor: connected ? Colors.white.withOpacity(0.02) : Colors.transparent,
                              ),
                              child: Text('Continue', style: TextStyle(color: connected ? Colors.white : Colors.white.withOpacity(0.45))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Column(
                  children: [
                    Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: Center(child: Icon(Icons.graphic_eq, color: Colors.white.withOpacity(0.9)))),
                    const SizedBox(height: 10),
                    Text(connected ? 'Voice guidance enabled' : 'Waiting for device...', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DesignerButtonTutorialPage extends StatefulWidget {
  const DesignerButtonTutorialPage({super.key});
  @override
  State<DesignerButtonTutorialPage> createState() => _DesignerButtonTutorialPageState();
}

class _DesignerButtonTutorialPageState extends State<DesignerButtonTutorialPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BleService>().startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = constraints.maxWidth * 0.85;
      final cardHeight = constraints.maxHeight * 0.55;

      return Column(
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(cardWidth * 0.5),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white.withOpacity(0.02), Colors.black.withOpacity(0.18)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 22),
                    Container(
                      height: 110,
                      alignment: Alignment.center,
                      child: Image.network(glassesImageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                    const SizedBox(height: 8),
                    Text('Get to Know Your Button', style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 16)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Expanded(child: Text('single press to read text', style: TextStyle(color: Colors.white.withOpacity(0.85)))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(width: 40, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                        const SizedBox(width: 12),
                        Expanded(child: Text('press and hold to describe your surroundings', style: TextStyle(color: Colors.white.withOpacity(0.85)))),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(width: double.infinity, height: 1, color: Colors.white.withOpacity(0.04)),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 160,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen()));
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.18)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: Text('Setup Complete', style: TextStyle(color: Colors.white.withOpacity(0.95))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Column(
            children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.12))), child: Center(child: Icon(Icons.graphic_eq, color: Colors.white.withOpacity(0.9)))),
              const SizedBox(height: 10),
              Text('Voice guidance enabled', style: TextStyle(color: Colors.white.withOpacity(0.9))),
            ],
          ),
          const Spacer(),
        ],
      );
    });
  }
}
