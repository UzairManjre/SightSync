import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/ble_service.dart';
import '../../services/settings_service.dart';
import '../../utils/theme.dart';
import '../../utils/size_config.dart';
import '../settings/settings_screen.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/link_visualizer.dart';
import 'controls_screen.dart';
import 'guide_screen.dart';
import 'main_hud.dart';
import '../onboarding/device_pairing_screen.dart';
import '../../services/performance_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _pc = PageController();
  int _idx  = 0;

  String _userName     = 'User';
  int    _batteryLeft  = 0;
  int    _batteryRight = 0;
  int    _rssiLeft     = 0;
  int    _rssiRight    = 0;
  String _thermalLeft  = 'COOL';
  String _thermalRight = 'COOL';
  bool   _isSyncing    = false;

  double _fps        = 0.0;
  int    _latencyMs  = 0;
  int    _memUsageMb = 0;

  String _singlePress = 'describe_scene';
  String _doublePress = 'read_text';
  String _longPress   = 'off';
  bool   _ctrlLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        setState(() => _userName = user.displayName?.split(' ').first ?? 'User');
      }

      final svc      = context.read<SettingsService>();
      final settings = await svc.fetchSettings();
      if (mounted && settings != null) {
        setState(() {
          _singlePress = settings.singlePressAction;
          _doublePress = settings.doublePressAction;
          _ctrlLoading = false;
        });
      } else if (mounted) {
        setState(() => _ctrlLoading = false);
      }

      final ble = context.read<BleService>();
      
      // Listen to Battery
      ble.batteryStream.listen((lvls) {
        if (mounted) {
          setState(() {
            _batteryLeft  = lvls['left']  ?? _batteryLeft;
            _batteryRight = lvls['right'] ?? _batteryRight;
          });
        }
      });

      // Listen to RSSI (Signal)
      ble.rssiStream.listen((lvls) {
        if (mounted) {
          setState(() {
            _rssiLeft  = lvls['left']  ?? _rssiLeft;
            _rssiRight = lvls['right'] ?? _rssiRight;
          });
        }
      });

      // Listen to Thermal
      ble.thermalStream.listen((stats) {
        if (mounted) {
          setState(() {
            _thermalLeft  = stats['left']  ?? _thermalLeft;
            _thermalRight = stats['right'] ?? _thermalRight;
          });
        }
      });

      // Listen to Performance
      final perf = PerformanceService();
      perf.startMonitoring();
      perf.addListener(() {
        if (mounted) {
          setState(() {
            _fps        = perf.fps;
            _latencyMs  = perf.latency;
            _memUsageMb = perf.memory;
          });
        }
      });
    } catch (e) {
      debugPrint('Dashboard init error: $e');
      if (mounted) setState(() => _ctrlLoading = false);
    }
  }

  Future<void> _sync() async {
    setState(() => _isSyncing = true);
    await context.read<SettingsService>().performManualSync();
    if (mounted) setState(() => _isSyncing = false);
  }

  Future<void> _update(String key, String val) async {
    setState(() {
      if (key == 'single_press_action') _singlePress = val;
      if (key == 'double_press_action') _doublePress = val;
      if (key == 'long_press_action')   _longPress   = val;
    });
    final svc = context.read<SettingsService>();
    final ble = context.read<BleService>();
    await svc.updateSetting(key, val);
    if (ble.leftDevice != null || ble.rightDevice != null) {
      await ble.writeCommand({'cmd': 'set_config', 'key': key, 'value': val});
    }
  }

  void _handleNav(int i) {
    if (i == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    } else {
      _pc.animateToPage(i, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutQuart);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final ble          = context.watch<BleService>();
    final isConnected  = ble.leftDevice != null || ble.rightDevice != null;
    final leftName     = ble.leftDevice?.platformName ?? '';
    final rightName    = ble.rightDevice?.platformName ?? '';

    return Scaffold(
      body: AmbientBackground(
        isPremium: true,
        child: Stack(
          children: [
            PageView(
              controller: _pc,
              onPageChanged: (i) => setState(() => _idx = i),
              physics: const BouncingScrollPhysics(),
              children: [
                _HomeTab(
                  userName: _userName,
                  isConnected: isConnected,
                  batteryLeft: _batteryLeft,
                  batteryRight: _batteryRight,
                  isSyncing: _isSyncing,
                  leftDeviceName: leftName,
                  rightDeviceName: rightName,
                  rssiLeft: _rssiLeft,
                  rssiRight: _rssiRight,
                  thermalLeft: _thermalLeft,
                  thermalRight: _thermalRight,
                  fps: _fps,
                  latency: _latencyMs,
                  memory: _memUsageMb,
                  onSync: _sync,
                  onOpenVision: () => _handleNav(1),
                  onOpenPairing: () {
                    if (isConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please disconnect your current device first before pairing a new one.')),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DevicePairingScreen(onNext: () => Navigator.pop(context)),
                        ),
                      );
                    }
                  },
                  onOpenControls: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ControlsScreen(
                        isListening: false,
                        onToggleListening: () {},
                        isLoading: _ctrlLoading,
                        singlePressAction: _singlePress,
                        doublePressAction: _doublePress,
                        longPressAction: _longPress,
                        onUpdateMapping: _update,
                      ),
                    ),
                  ),
                ),
                MainVisionHUD(
                  isLoading: _ctrlLoading,
                  singlePressAction: _singlePress,
                  doublePressAction: _doublePress,
                  longPressAction: _longPress,
                  onUpdateMapping: _update,
                ),
                const GuideScreen(),
              ],
            ),
            FloatingNavBar(currentIndex: _idx, onTap: _handleNav),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  HOME TAB
// ──────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final String userName;
  final bool   isConnected;
  final int    batteryLeft;
  final int    batteryRight;
  final int    rssiLeft;
  final int    rssiRight;
  final String thermalLeft;
  final String thermalRight;
  final double fps;
  final int    latency;
  final int    memory;
  final bool   isSyncing;
  final String leftDeviceName;
  final String rightDeviceName;
  final VoidCallback onSync;
  final VoidCallback onOpenVision;
  final VoidCallback onOpenPairing;
  final VoidCallback onOpenControls;

  const _HomeTab({
    required this.userName,
    required this.isConnected,
    required this.batteryLeft,
    required this.batteryRight,
    required this.rssiLeft,
    required this.rssiRight,
    required this.thermalLeft,
    required this.thermalRight,
    required this.fps,
    required this.latency,
    required this.memory,
    required this.isSyncing,
    required this.leftDeviceName,
    required this.rightDeviceName,
    required this.onSync,
    required this.onOpenVision,
    required this.onOpenPairing,
    required this.onOpenControls,
  });

  @override
  Widget build(BuildContext context) {
    // System battery = weakest unit (the limiting factor)
    final int systemBattery = isConnected
        ? (() {
            final vals = [if (batteryLeft > 0) batteryLeft, if (batteryRight > 0) batteryRight];
            return vals.isEmpty ? 0 : vals.reduce((a, b) => a < b ? a : b);
          })()
        : 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 64),

          // ── Header ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIGHTSYNC OS',
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hello, $userName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onSync,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Icon(
                      isSyncing ? Icons.hourglass_empty_rounded : Icons.sync_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Overall System Battery Bar ──────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _TopSystemBattery(battery: systemBattery, isConnected: isConnected),
          ),

          const SizedBox(height: 24),

          // ── Connection Status Card ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _ConnectionCard(
              isConnected: isConnected,
              leftDeviceName: leftDeviceName,
              rightDeviceName: rightDeviceName,
              batteryLeft: batteryLeft,
              batteryRight: batteryRight,
              onOpenPairing: onOpenPairing,
            ),
          ),

          const SizedBox(height: 14),



          // ── Link Visualizer ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LinkVisualizer(
              leftActive: isConnected && batteryLeft > 0,
              rightActive: isConnected && batteryRight > 0,
            ),
          ),

          const SizedBox(height: 20),

          // ── Diagnostic Cards ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _DiagnosticCard(
                    title: 'LEFT UNIT',
                    deviceName: leftDeviceName.isNotEmpty ? leftDeviceName : 'OFFLINE',
                    power: batteryLeft > 0 ? batteryLeft : (isConnected ? 0 : 0),
                    thermalStr: isConnected ? thermalLeft : 'N/A',
                    rssi: isConnected ? rssiLeft : 0,
                    isActive: isConnected && (batteryLeft > 0 || leftDeviceName.isNotEmpty),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _DiagnosticCard(
                    title: 'RIGHT UNIT',
                    deviceName: rightDeviceName.isNotEmpty ? rightDeviceName : 'OFFLINE',
                    power: batteryRight > 0 ? batteryRight : (isConnected ? 0 : 0),
                    thermalStr: isConnected ? thermalRight : 'N/A',
                    rssi: isConnected ? rssiRight : 0,
                    isActive: isConnected && (batteryRight > 0 || rightDeviceName.isNotEmpty),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Stats Bar ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _StatsBar(
              isConnected: isConnected, 
              fps: fps,
              latency: latency,
              memory: memory,
            ),
          ),

          const SizedBox(height: 20),

          // ── Quick Actions ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.tune_rounded,
                    label: 'PROTOCOLS',
                    subtitle: 'Button Config',
                    onTap: onOpenControls,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.filter_center_focus_rounded,
                    label: 'VISION HUD',
                    subtitle: 'Live Camera',
                    onTap: onOpenVision,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 140),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  DIAGNOSTIC CARD
// ──────────────────────────────────────────────────────────────────────────────
class _DiagnosticCard extends StatelessWidget {
  final String title;
  final String deviceName;
  final int    power;
  final String thermalStr;
  final int    rssi;
  final bool   isActive;

  const _DiagnosticCard({
    required this.title,
    required this.deviceName,
    required this.power,
    required this.thermalStr,
    required this.rssi,
    required this.isActive,
  });

  Color _themeColor() {
    if (!isActive) return Colors.white.withOpacity(0.2);
    if (thermalStr == 'HOT') return AppColors.error;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.glassDecoration(opacity: 0.04, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.success : Colors.white12,
                  boxShadow: isActive
                      ? [BoxShadow(color: AppColors.success.withOpacity(0.5), blurRadius: 6)]
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isActive ? deviceName : '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'SpaceGrotesk',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          _MetricRow(
            label: 'POWER',
            value: isActive ? '$power%' : '—',
            color: isActive ? _battColor(power) : Colors.white12,
          ),
          const SizedBox(height: 10),
          _DiagRow(
            label: 'THERMAL',
            value: isActive ? (thermalStr == 'HOT' ? 'WARNING' : 'STABLE') : '--',
            color: thermalStr == 'HOT' ? AppColors.error : AppColors.primary,
          ),
          _DiagRow(
            label: 'SIGNAL',
            value: isActive ? '$rssi dBm' : '--',
            color: isActive ? (rssi > -70 ? AppColors.success : AppColors.warning) : AppColors.primary,
          ),
        ],
      ),
    );
  }

  Color _battColor(int v) {
    if (v > 50) return AppColors.success;
    if (v > 20) return AppColors.warning;
    return AppColors.error;
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _MetricRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            )),
        Text(value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'SpaceGrotesk',
            )),
      ],
    );
  }
}

class _DiagRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _DiagRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            )),
        Text(value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFamily: 'SpaceGrotesk',
            )),
      ],
    );
  }
}


// ──────────────────────────────────────────────────────────────────────────────
//  CONNECTION CARD
// ──────────────────────────────────────────────────────────────────────────────
class _ConnectionCard extends StatelessWidget {
  final bool isConnected;
  final String leftDeviceName;
  final String rightDeviceName;
  final int batteryLeft;
  final int batteryRight;
  final VoidCallback onOpenPairing;

  const _ConnectionCard({
    required this.isConnected,
    required this.leftDeviceName,
    required this.rightDeviceName,
    required this.batteryLeft,
    required this.batteryRight,
    required this.onOpenPairing,
  });

  @override
  Widget build(BuildContext context) {
    final connectedDevices = [
      if (leftDeviceName.isNotEmpty) leftDeviceName,
      if (rightDeviceName.isNotEmpty) rightDeviceName,
    ];
    final deviceLabel = connectedDevices.isEmpty ? 'No Device Found' : connectedDevices.join(' · ');

    return InkWell(
      onTap: onOpenPairing,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration(opacity: isConnected ? 0.08 : 0.04, radius: 28),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? AppColors.primary.withOpacity(0.1) : Colors.white10,
              ),
              child: Icon(
                isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                color: isConnected ? AppColors.primary : Colors.white24,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isConnected ? 'DEVICE LINKED' : 'NOT CONNECTED', style: TextStyle(color: isConnected ? AppColors.primary : Colors.white24, fontSize: 9, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(isConnected ? deviceLabel : 'Scan for Glasses', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'SpaceGrotesk')),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  OVERALL SYSTEM BATTERY BAR (TOP)
// ──────────────────────────────────────────────────────────────────────────────
class _TopSystemBattery extends StatelessWidget {
  final int  battery;
  final bool isConnected;
  const _TopSystemBattery({required this.battery, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final c = isConnected ? (battery > 50 ? const Color(0xFF4D85FF) : AppColors.warning) : Colors.white10;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isConnected ? 'SYSTEM POWER' : 'OFFLINE', style: TextStyle(color: isConnected ? Colors.white38 : Colors.white10, fontSize: 8, fontWeight: FontWeight.w900)),
            Text(isConnected ? '$battery%' : '--', style: TextStyle(color: isConnected ? c : Colors.white10, fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(2)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: isConnected ? battery / 100.0 : 0.05,
            child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          ),
        ),
      ],
    );
  }
}
class _StatsBar extends StatelessWidget {
  final bool isConnected;
  final double fps;
  final int latency;
  final int memory;

  const _StatsBar({
    required this.isConnected,
    required this.fps,
    required this.latency,
    required this.memory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'FPS', value: isConnected ? fps.toStringAsFixed(0) : '—'),
          _StatDivider(),
          _StatItem(label: 'LATENCY', value: isConnected ? '${latency}ms' : '—'),
          _StatDivider(),
          _StatItem(label: 'MODEL', value: 'Q-V3'),
          _StatDivider(),
          _StatItem(label: 'MEM', value: isConnected ? '${memory}MB' : '—'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            )),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontFamily: 'SpaceGrotesk',
            )),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 0.5, height: 28, color: Colors.white12);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  QUICK ACTION TILE
// ──────────────────────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: AppTheme.glassDecoration(opacity: 0.04, radius: 20),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  PULSING STATUS DOT
// ──────────────────────────────────────────────────────────────────────────────
class _StatusPulse extends StatefulWidget {
  const _StatusPulse();
  @override
  State<_StatusPulse> createState() => _StatusPulseState();
}

class _StatusPulseState extends State<_StatusPulse> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ble         = context.watch<BleService>();
    final isConnected = ble.leftDevice != null || ble.rightDevice != null;
    final color       = isConnected ? AppColors.success : AppColors.textTertiary;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(_pulse.value),
          boxShadow: isConnected
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5, spreadRadius: 1)]
              : null,
        ),
      ),
    );
  }
}