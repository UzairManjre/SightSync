import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:math' as math;
import '../../utils/theme.dart';
import '../../services/ble_service.dart';
import '../../widgets/ambient_background.dart';
import 'onboarding_screens.dart'; // To access PairingCodePage

class DevicePairingScreen extends StatefulWidget {
  final VoidCallback onNext;
  const DevicePairingScreen({super.key, required this.onNext});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> {
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

    return Scaffold(
      body: AmbientBackground(
        isPremium: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connect Your\nModule',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -1.2,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    if (Navigator.of(context).canPop())
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: widget.onNext,
                      ),
                  ],
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
                              
                              try {
                                await ble.connectLeft(r.device);
                                await ble.writeCommand({'type': 'pairing_pin', 'pin': pin});

                                if (!mounted) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PairingCodePage(
                                      deviceName: name,
                                      pin: pin,
                                      onConfirm: widget.onNext,
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
              ],
            ),
          ),
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
