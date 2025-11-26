// lib/screens/onboarding/onboarding_screens.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../services/ble_service.dart';
import '../../utils/theme.dart';
import '../dashboard/dashboard_screen.dart';

const String backgroundImageUrl = '/mnt/data/6c49ffa0-be1d-4a9b-9c13-264460091105.png';
const String glassesImageUrl = '/mnt/data/93a24752-c1a5-4f28-8408-48b61dc2eb01.png';

class OnboardingScreen extends StatefulWidget {
  final int initialPage;

  const OnboardingScreen({super.key, this.initialPage = 0});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
    _currentPage = widget.initialPage;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void goToNextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient matching the design
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4facfe), // Light Blue
                    Color(0xFF00f2fe), // Cyan accent
                    Color(0xFF1A1A2E), // Dark Blue
                    Color(0xFF000000), // Black
                  ],
                  stops: [0.0, 0.2, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // Radial overlay for depth
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.5),
                  radius: 1.5,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    physics: const NeverScrollableScrollPhysics(), // Lock swipe, force interaction
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
              height: 1.1,
              fontWeight: FontWeight.w300, // Thinner font as per design
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Follow the on-screen steps or use voice guidance\nto complete your setup.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, height: 1.5),
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
                  color: Colors.white.withOpacity(0.05), // Slight fill
                ),
                child: Center(child: Icon(Icons.graphic_eq, color: Colors.white.withOpacity(0.9))),
              ),
              const SizedBox(width: 16),
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bleService = context.read<BleService>();
      await bleService.init(); // Request permissions
      bleService.startScan();
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
      final cardHeight = constraints.maxHeight * 0.65; // Taller card

      return Column(
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1535).withOpacity(0.6), // Dark blue glass
                borderRadius: BorderRadius.circular(cardWidth * 0.1), // Rounded corners
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cardWidth * 0.1),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Icon(Icons.bluetooth, size: 60, color: Colors.blue.shade200),
                      const SizedBox(height: 20),
                      Text(
                        'Make sure Bluetooth is turned on',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      Container(width: cardWidth * 0.8, height: 1, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 20),
                      Text('Select your device', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: StreamBuilder<List<ScanResult>>(
                          stream: bleService.scanResults,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(color: Colors.white54),
                                    const SizedBox(height: 16),
                                    Text('Searching...', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                                  ],
                                ),
                              );
                            }
                            final results = snapshot.data!;
                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: results.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final r = results[i];
                                final deviceName = r.device.platformName.isNotEmpty ? r.device.platformName : (r.device.name.isNotEmpty ? r.device.name : 'Unknown Device');
                                return GestureDetector(
                                  onTap: () => _onDeviceTap(context, r),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.headphones, color: Colors.white.withOpacity(0.9), size: 20),
                                        const SizedBox(width: 16),
                                        Expanded(child: Text(deviceName, style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 16))),
                                        Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DesignerButtonTutorialPage()),
              );
            },
            child: Text(
              "Skip Setup",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              Container(
                width: 50, 
                height: 50, 
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  border: Border.all(color: Colors.white.withOpacity(0.2))
                ), 
                child: Center(child: Icon(Icons.graphic_eq, color: Colors.white.withOpacity(0.9), size: 24))
              ),
              const SizedBox(height: 10),
              Text('Voice guidance enabled', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 30),
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
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4facfe),
                    Color(0xFF00f2fe),
                    Color(0xFF1A1A2E),
                    Color(0xFF000000),
                  ],
                  stops: [0.0, 0.2, 0.6, 1.0],
                ),
              ),
            ),
          ),
           Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.5),
                  radius: 1.5,
                  colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.height * 0.6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1535).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.1),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Icon(Icons.bluetooth_connected, size: 64, color: Colors.blue.shade200),
                          const SizedBox(height: 20),
                          Text(widget.deviceName, style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 18)),
                          const SizedBox(height: 20),
                          Container(height: 1, width: MediaQuery.of(context).size.width * 0.6, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 20),
                          Text('Confirm the pairing code.', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16)),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _codeDigits.map((d) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 40,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Center(child: Text(d, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: 160,
                            child: OutlinedButton(
                              onPressed: connected
                                  ? () {
                                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DesignerButtonTutorialPage()));
                              }
                                  : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: connected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                              ),
                              child: Text('Continue', style: TextStyle(color: connected ? Colors.white : Colors.white.withOpacity(0.4), fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Column(
                  children: [
                    Container(
                      width: 50, 
                      height: 50, 
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.white.withOpacity(0.2))
                      ), 
                      child: Center(child: Icon(Icons.graphic_eq, color: Colors.white.withOpacity(0.9), size: 24))
                    ),
                    const SizedBox(height: 10),
                    Text(connected ? 'Voice guidance enabled' : 'Waiting for device...', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 30),
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
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4facfe),
                    Color(0xFF00f2fe),
                    Color(0xFF1A1A2E),
                    Color(0xFF000000),
                  ],
                  stops: [0.0, 0.2, 0.6, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.5),
                  radius: 1.5,
                  colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              final cardWidth = constraints.maxWidth * 0.85;
              final cardHeight = constraints.maxHeight * 0.65;

              return Column(
                children: [
                  const Spacer(),
                  Center(
                    child: Container(
                      width: cardWidth,
                      height: cardHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1535).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(cardWidth * 0.1),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(cardWidth * 0.1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              // Replaced Image.network with Icon since asset is missing
                              Icon(Icons.smart_toy, size: 100, color: Colors.white.withOpacity(0.9)),
                              const SizedBox(height: 20),
                              Text('Get to Know Your Button', style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 18)),
                              const SizedBox(height: 30),
                              Row(
                                children: [
                                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                                  const SizedBox(width: 16),
                                  Expanded(child: Text('single press to read text', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16))),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Container(width: 40, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                                  const SizedBox(width: 16),
                                  Expanded(child: Text('press and hold to describe your surroundings', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16))),
                                ],
                              ),
                              const SizedBox(height: 30),
                              Container(width: double.infinity, height: 1, color: Colors.white.withOpacity(0.1)),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: 180,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen()));
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: Text('Setup Complete', style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Container(
                        width: 50, 
                        height: 50, 
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          border: Border.all(color: Colors.white.withOpacity(0.2))
                        ), 
                        child: Center(child: Icon(Icons.graphic_eq, color: Colors.white.withOpacity(0.9), size: 24))
                      ),
                      const SizedBox(height: 10),
                      Text('Voice guidance enabled', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
