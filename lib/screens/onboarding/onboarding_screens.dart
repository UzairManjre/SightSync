// lib/screens/onboarding/onboarding_screens.dart
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../services/ble_service.dart';
import '../../utils/theme.dart';
import '../../utils/size_config.dart';
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
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.authGradientTop,
                    Colors.black,
                  ],
                  stops: [0.0, 0.8],
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
    SizeConfig.init(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SizeConfig.w(28), SizeConfig.h(60), SizeConfig.w(28), SizeConfig.h(36)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            'SightSync is ready\nto guide you',
            style: TextStyle(
              color: Colors.white,
              fontSize: SizeConfig.sp(42),
              height: 1.1,
              fontWeight: FontWeight.w300,
              letterSpacing: -1.0,
            ),
          ),
          SizedBox(height: SizeConfig.h(24)),
          Text(
            'Follow the on-screen steps or use voice guidance\nto complete your setup.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: SizeConfig.sp(15),
              height: 1.5,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: SizeConfig.w(54),
                height: SizeConfig.w(54),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Center(
                  child: Icon(
                    Icons.graphic_eq,
                    color: Colors.white.withOpacity(0.9),
                    size: SizeConfig.sp(24),
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.w(16)),
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
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  @override
  void initState() {
    super.initState();
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (mounted) setState(() => _adapterState = state);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bleService = context.read<BleService>();
      await bleService.init();
      bleService.startScan();
    });
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onConnectGlasses(BuildContext context, List<ScanResult> results) async {
    final bleService = context.read<BleService>();
    
    // Logic: Find SightSync devices or XIAO modules
    // For now, let's look for anything that looks like our modules
    final sightSyncDevices = results.where((r) => 
      r.device.platformName.contains('SightSync') || 
      r.device.platformName.contains('XIAO') ||
      r.device.name.contains('SightSync')
    ).toList();

    // TEMPORARY TEST: Change < 2 to < 1
    if (sightSyncDevices.length < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please make sure the arm module is powered on.'))
      );
      return;
    }

    // Identitfy left/right (this is a placeholder logic, usually based on suffix -L/-R)
    final d1 = sightSyncDevices[0].device;
    // TEST ONLY: Comment out right arm requirement
    // final d2 = sightSyncDevices[1].device;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text('Syncing Arms...', style: TextStyle(color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );

    try {
      await bleService.stopScan();
      // Connect to left arm only for testing
      await Future.wait([
        bleService.connectLeft(d1),
        // TEST ONLY: Comment out right arm connection
        // bleService.connectRight(d2),
      ]);

      if (context.mounted) {
        Navigator.of(context).pop(); // pop dialog
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PairingConfirmPage(deviceName: 'SightSync Glasses')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleService = context.watch<BleService>();
    SizeConfig.init(context);

    return Column(
      children: [
        const Spacer(),
        Center(
          child: Container(
            width: SizeConfig.w(320),
            height: SizeConfig.w(320),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F1535).withOpacity(0.4),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bluetooth, size: SizeConfig.w(80), color: Colors.white.withOpacity(0.9)),
                    SizedBox(height: SizeConfig.h(20)),
                    Text(
                      'Make sure Bluetooth is turned on',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: SizeConfig.sp(14)),
                    ),
                    SizedBox(height: SizeConfig.h(12)),
                    Container(width: SizeConfig.w(180), height: 1, color: Colors.white.withOpacity(0.1)),
                    SizedBox(height: SizeConfig.h(12)),
                    Text(
                      'Select your device',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: SizeConfig.sp(12)),
                    ),
                    SizedBox(height: SizeConfig.h(10)),
                    StreamBuilder<List<ScanResult>>(
                      stream: bleService.scanResults,
                      builder: (context, snapshot) {
                        final results = snapshot.data ?? [];
                        
                        // DEBUG: Print all discovered devices to Xcode console
                        if (results.isNotEmpty) {
                          print("--- BLE SCAN FILTER ---");
                          for (var r in results) {
                            print("Found: PlatformName: '${r.device.platformName}', Name: '${r.device.name}', ID: ${r.device.remoteId}");
                          }
                          print("-----------------------");
                        }

                        final sightSyncFound = results.any((r) => 
                          r.device.platformName.contains('SightSync') || 
                          r.device.platformName.contains('XIAO') ||
                          r.device.name.contains('SightSync')
                        );

                        if (_adapterState != BluetoothAdapterState.on) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Bluetooth is OFF.', style: TextStyle(color: AppColors.error, fontSize: SizeConfig.sp(14), fontWeight: FontWeight.bold)),
                          );
                        }

                        return Column(
                          children: [
                            if (sightSyncFound)
                              GestureDetector(
                                onTap: () => _onConnectGlasses(context, results),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'SightSync Glasses',
                                    style: TextStyle(color: Colors.white, fontSize: SizeConfig.sp(14), fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            if (!sightSyncFound)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('Searching...', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: SizeConfig.sp(12))),
                              ),
                            // DEBUG LIST
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 120, // scrollable area
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: results.length,
                                itemBuilder: (context, index) {
                                  final r = results[index];
                                  final name = r.device.platformName.isNotEmpty ? r.device.platformName : (r.device.name.isNotEmpty ? r.device.name : 'Unknown');
                                  return Text(
                                    "Found: $name", 
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                                    textAlign: TextAlign.center,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
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
              width: SizeConfig.w(50),
              height: SizeConfig.w(50),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Center(child: Icon(Icons.graphic_eq, color: Colors.white.withOpacity(0.9), size: SizeConfig.sp(22))),
            ),
            SizedBox(height: SizeConfig.h(10)),
            Text('Voice guidance enabled', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: SizeConfig.sp(12))),
          ],
        ),
        SizedBox(height: SizeConfig.h(30)),
      ],
    );
  }
}

class PairingConfirmPage extends StatefulWidget {
  final String deviceName;
  const PairingConfirmPage({required this.deviceName, super.key});

  @override
  State<PairingConfirmPage> createState() => _PairingConfirmPageState();
}

class _PairingConfirmPageState extends State<PairingConfirmPage> {
  final List<String> _codeDigits = ['6', '6', '8', '0', '0', '1'];

  @override
  Widget build(BuildContext context) {
    final bleService = context.watch<BleService>();
    final bothConnected = bleService.leftDevice != null && bleService.rightDevice != null;
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: SizeConfig.w(320),
                    height: SizeConfig.w(320),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F1535).withOpacity(0.4),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth_connected, size: SizeConfig.w(70), color: Colors.blue.shade200),
                            SizedBox(height: SizeConfig.h(10)),
                            Text(widget.deviceName, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: SizeConfig.sp(16))),
                            SizedBox(height: SizeConfig.h(12)),
                            Container(width: SizeConfig.w(180), height: 1, color: Colors.white.withOpacity(0.1)),
                            SizedBox(height: SizeConfig.h(12)),
                            Text('Confirm the pairing code.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: SizeConfig.sp(14))),
                            SizedBox(height: SizeConfig.h(20)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _codeDigits.map((d) {
                                return Container(
                                  margin: EdgeInsets.symmetric(horizontal: SizeConfig.w(4)),
                                  width: SizeConfig.w(36),
                                  height: SizeConfig.h(46),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Center(
                                    child: Text(d, style: TextStyle(color: Colors.white, fontSize: SizeConfig.sp(18), fontWeight: FontWeight.w600)),
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: SizeConfig.h(25)),
                            GestureDetector(
                              onTap: bothConnected ? () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const DesignerButtonTutorialPage())
                                );
                              } : null,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: SizeConfig.w(32), vertical: SizeConfig.h(10)),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(bothConnected ? 0.3 : 0.1)),
                                  color: bothConnected ? Colors.white.withOpacity(0.05) : Colors.transparent,
                                ),
                                child: Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: bothConnected ? Colors.white : Colors.white.withOpacity(0.35),
                                    fontSize: SizeConfig.sp(14),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
                      width: SizeConfig.w(50),
                      height: SizeConfig.w(50),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Center(child: Icon(Icons.graphic_eq, color: Colors.white.withOpacity(0.9), size: SizeConfig.sp(22))),
                    ),
                    SizedBox(height: SizeConfig.h(10)),
                    Text(
                      bothConnected ? 'Voice guidance enabled' : 'Waiting for sync...',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: SizeConfig.sp(12)),
                    ),
                  ],
                ),
                SizedBox(height: SizeConfig.h(30)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class DesignerButtonTutorialPage extends StatelessWidget {
  const DesignerButtonTutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Column(
      children: [
        const Spacer(),
        Center(
          child: Container(
            width: SizeConfig.w(320),
            height: SizeConfig.w(320),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F1535).withOpacity(0.4),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.w(30)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy_outlined, size: SizeConfig.w(60), color: Colors.blue.shade200),
                      SizedBox(height: SizeConfig.h(10)),
                      Text(
                        'Get to Know Your Button',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: SizeConfig.sp(16), fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: SizeConfig.h(20)),
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle)),
                          SizedBox(width: 12),
                          Expanded(child: Text('Single press to read text', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: SizeConfig.sp(13)))),
                        ],
                      ),
                      SizedBox(height: SizeConfig.h(12)),
                      Row(
                        children: [
                          Container(width: 24, height: 8, decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(4))),
                          SizedBox(width: 12),
                          Expanded(child: Text('Long press to describe scene', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: SizeConfig.sp(13)))),
                        ],
                      ),
                      SizedBox(height: SizeConfig.h(30)),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen()));
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: SizeConfig.w(28), vertical: SizeConfig.h(10)),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                            color: Colors.white.withOpacity(0.05),
                          ),
                          child: Text(
                            'Setup Complete',
                            style: TextStyle(color: Colors.white, fontSize: SizeConfig.sp(14), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        Column(
          children: [
            Container(
              width: SizeConfig.w(50),
              height: SizeConfig.w(50),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Center(child: Icon(Icons.graphic_eq, color: Colors.white.withOpacity(0.9), size: SizeConfig.sp(22))),
            ),
            SizedBox(height: SizeConfig.h(10)),
            Text('Voice guidance enabled', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: SizeConfig.sp(12))),
          ],
        ),
        SizedBox(height: SizeConfig.h(30)),
      ],
    );
  }
}
