import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../services/ble_service.dart';
import '../../services/vision_log_service.dart';
import '../../services/ai_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────────
class _Feature {
  final String name;
  final IconData icon;
  final Color color;
  final String bleCmd;

  const _Feature(this.name, this.icon, this.color, this.bleCmd);
}

const _kFeatures = [
  _Feature('Scene Description', Icons.auto_awesome_rounded, Color(0xFF3B82F6), 'describe_scene'),
  _Feature('Text Reading', Icons.text_fields_rounded, Color(0xFF8B5CF6), 'read_text'),
  _Feature('Currency AI', Icons.currency_exchange_rounded, Color(0xFF06B6D4), 'currency_detect'),
  _Feature('Face Match', Icons.face_retouching_natural_rounded, Color(0xFF10B981), 'face_match'),
];

// ─────────────────────────────────────────────────────────────────────────────
// ROOT WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class MainVisionHUD extends StatefulWidget {
  final bool isLoading;
  final String singlePressAction;
  final String doublePressAction;
  final String longPressAction;
  final Future<void> Function(String key, String value) onUpdateMapping;

  const MainVisionHUD({
    super.key,
    required this.isLoading,
    required this.singlePressAction,
    required this.doublePressAction,
    required this.longPressAction,
    required this.onUpdateMapping,
  });

  @override
  State<MainVisionHUD> createState() => _MainVisionHUDState();
}

class _MainVisionHUDState extends State<MainVisionHUD> {
  final _logService = VisionLogService();
  bool _historyOpen = false;
  bool _feedFullscreen = false;

  // ── FULLSCREEN OVERLAY ───────────────────────────────────────────────────
  void _openFullscreen(String? streamUrl) async {
    setState(() => _feedFullscreen = true);
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullscreenFeed(
          streamUrl: streamUrl,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted) setState(() => _feedFullscreen = false);
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final isConnected = ble.leftDevice != null || ble.rightDevice != null;
    final ip = ble.activeDeviceIp;
    final streamUrl = (ip != null && ip != '0.0.0.0') ? 'http://$ip/stream' : null;

    // ── CRITICAL: return a plain widget, NEVER a Scaffold.
    // This page lives inside the PageView in dashboard_screen.dart which is
    // already inside a Scaffold+AmbientBackground. Adding another Scaffold here
    // causes the grey canvas you were seeing on iOS.
    return CustomScrollView(
      physics: isConnected ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
      slivers: [
        // ── Top spacing (below status bar) ──
        const SliverToBoxAdapter(child: SizedBox(height: 72)),

        // ── Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Try some Features out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _StatusBadge(isConnected: isConnected, ble: ble),
            ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        // ── Main Content Area ──
        if (!isConnected)
          // OFFLINE STATE
          SliverFillRemaining(
            hasScrollBody: false,
            child: _OfflineState(),
          )
        else ...[
          // ONLINE STATE — side-by-side: feature list + camera feed
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _MainContentRow(
                streamUrl: streamUrl,
                isFeedActive: !_feedFullscreen,
                deviceIp: ip,
                logService: _logService,
                aiService: context.watch<AiService>(),
                onExpand: () => _openFullscreen(streamUrl),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── History Section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _HistorySection(
                logService: _logService,
                isOpen: _historyOpen,
                onToggle: () => setState(() => _historyOpen = !_historyOpen),
              ),
            ),
          ),
        ],

        // Bottom nav padding
        if (isConnected) const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isConnected;
  final BleService ble;
  const _StatusBadge({required this.isConnected, required this.ble});

  @override
  Widget build(BuildContext context) {
    final color   = isConnected ? AppColors.success : AppColors.textTertiary;
    final label   = isConnected
        ? 'Connected — ${ble.leftDevice?.platformName ?? ble.rightDevice?.platformName ?? ''}'
        : 'System offline';

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OFFLINE STATE
// ─────────────────────────────────────────────────────────────────────────────
class _OfflineState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
              ),
              child: Icon(
                Icons.bluetooth_disabled_rounded,
                color: Colors.white.withValues(alpha: 0.25),
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Device Not Connected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'SpaceGrotesk',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Please connect your glasses to access the AI features.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN CONTENT ROW — Feature list (50%) + Camera feed (50%)
// ─────────────────────────────────────────────────────────────────────────────
class _MainContentRow extends StatelessWidget {
  final String? streamUrl;
  final String? deviceIp;
  final bool isFeedActive;
  final VisionLogService logService;
  final AiService aiService;
  final VoidCallback onExpand;
  const _MainContentRow({
    required this.streamUrl,
    required this.isFeedActive,
    required this.deviceIp,
    required this.logService,
    required this.aiService,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamically measure half the available width
    return LayoutBuilder(
      builder: (context, constraints) {
        final colW = (constraints.maxWidth - 12) / 2; // 12px gap
        // Height = 4 feature tiles with padding; keep it as a square on the feed side
        final height = colW;

        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Feature Bubbles (left 50%) ──
              SizedBox(
                width: colW,
                child: Column(
                  children: [
                    for (int i = 0; i < _kFeatures.length; i++) ...[
                      _FeatureBubble(
                        feature: _kFeatures[i],
                        logService: logService,
                        aiService: aiService,
                        deviceIp: deviceIp,
                      ),
                      if (i < _kFeatures.length - 1) const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Camera Feed (right 50%) ──
              SizedBox(
                width: colW,
                child: _CameraFeedWidget(
                  streamUrl: streamUrl,
                  isFeedActive: isFeedActive,
                  onExpand: onExpand,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureBubble extends StatefulWidget {
  final _Feature feature;
  final VisionLogService logService;
  final AiService aiService;
  final String? deviceIp;
  const _FeatureBubble({
    required this.feature,
    required this.logService,
    required this.aiService,
    required this.deviceIp,
  });

  @override
  State<_FeatureBubble> createState() => _FeatureBubbleState();
}

class _FeatureBubbleState extends State<_FeatureBubble> {
  bool _pressed = false;
  bool _processing = false;

  void _showSnack(String msg, {Color? bg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: bg ?? AppColors.surfaceContainer,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _runFeature() async {
    if (_processing || widget.aiService.isBusy) {
      _showSnack('AI is already processing. Please wait.');
      return;
    }
    if (widget.deviceIp == null) {
      _showSnack('No camera IP available. Check glasses connection.');
      return;
    }

    setState(() => _processing = true);

    // Show "capturing" feedback immediately
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Capturing frame for ${widget.feature.name}...')),
          ],
        ),
        backgroundColor: AppColors.surfaceContainer,
        duration: const Duration(seconds: 30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      // 1. Grab a frame from the glasses
      final imageBytes = await widget.aiService.captureFrameFromGlasses(widget.deviceIp!);
      if (imageBytes == null) {
        _showSnack('Could not capture frame. Is the /capture endpoint running on the ESP32?', bg: AppColors.error);
        return;
      }

      // 2. Dispatch to the correct AI feature — result is spoken + Firestore-logged inside AiService
      final f = widget.feature;
      AiResult result;
      switch (f.name) {
        case 'Scene Description':
          result = await widget.aiService.describeScene(imageBytes: imageBytes, logService: widget.logService);
          break;
        case 'Text Reading':
          result = await widget.aiService.readText(imageBytes: imageBytes, logService: widget.logService);
          break;
        case 'Currency AI':
          result = await widget.aiService.detectCurrency(imageBytes: imageBytes, logService: widget.logService);
          break;
        case 'Face Match':
          result = await widget.aiService.describeFace(imageBytes: imageBytes, logService: widget.logService);
          break;
        default:
          result = const AiResult(featureName: 'Unknown', output: 'Feature not implemented.', latencyMs: 0);
      }

      // 3. Show result (the TTS speaking is handled inside AiService already)
      _showSnack(
        result.isSuccess
            ? '${f.name} — ${result.latencyMs}ms  |  ${result.output.length > 60 ? result.output.substring(0, 60) + "…" : result.output}'
            : '${f.name} failed: ${result.error}',
        bg: result.isSuccess ? AppColors.success : AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _runFeature,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _pressed
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed
                  ? f.color.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: f.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(f.icon, color: f.color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  f.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SpaceGrotesk',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAMERA FEED WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _CameraFeedWidget extends StatelessWidget {
  final String? streamUrl;
  final bool isFeedActive;
  final VoidCallback onExpand;
  const _CameraFeedWidget({required this.streamUrl, required this.isFeedActive, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF080B14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Feed or placeholder
            if (streamUrl != null && isFeedActive)
              Mjpeg(
                isLive: true,
                stream: streamUrl!,
                fit: BoxFit.cover,
                error: (ctx, e, st) => const _FeedPlaceholder(isError: true),
                loading: (ctx) => const _FeedPlaceholder(isLoading: true),
              )
            else if (streamUrl != null && !isFeedActive)
              const _FeedPlaceholder(customMessage: 'Enlarged')
            else
              const _FeedPlaceholder(),

            // Bottom gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),

            // LIVE dot
            Positioned(
              bottom: 8, left: 10,
              child: _LiveIndicator(streaming: streamUrl != null),
            ),

            // Expand button
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: onExpand,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  final bool streaming;
  const _LiveIndicator({required this.streaming});
  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.streaming ? AppColors.error : Colors.white38;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _ctrl,
          child: Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          widget.streaming ? 'LIVE' : 'STANDBY',
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _FeedPlaceholder extends StatelessWidget {
  final bool isLoading;
  final bool isError;
  final String? customMessage;
  const _FeedPlaceholder({this.isLoading = false, this.isError = false, this.customMessage});

  @override
  Widget build(BuildContext context) {
    String message = isLoading ? 'Connecting...' : isError ? 'Stream failed' : 'No signal';
    if (customMessage != null) message = customMessage!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppColors.primary,
              ),
            )
          else
            Icon(
              isError ? Icons.signal_wifi_off_rounded : (customMessage != null ? Icons.zoom_out_map_rounded : Icons.camera_alt_outlined),
              color: Colors.white.withValues(alpha: 0.15),
              size: 28,
            ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULLSCREEN FEED (navigated via PageRouteBuilder — avoids Scaffold nesting)
// ─────────────────────────────────────────────────────────────────────────────
class _FullscreenFeed extends StatelessWidget {
  final String? streamUrl;
  final VoidCallback onClose;
  const _FullscreenFeed({required this.streamUrl, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          SizedBox.expand(
            child: streamUrl != null
                ? Mjpeg(
                    isLive: true,
                    stream: streamUrl!,
                    fit: BoxFit.cover,
                    error: (ctx, e, st) => const _FeedPlaceholder(isError: true),
                    loading: (ctx) => const _FeedPlaceholder(isLoading: true),
                  )
                : const _FeedPlaceholder(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: onClose,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Icon(Icons.fullscreen_exit_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HISTORY SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _HistorySection extends StatelessWidget {
  final VisionLogService logService;
  final bool isOpen;
  final VoidCallback onToggle;

  const _HistorySection({
    required this.logService,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1),
      ),
      child: Column(
        children: [
          // ── Header row ──
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Feature History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withValues(alpha: 0.35),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded log list ──
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isOpen
                ? StreamBuilder<List<VisionLog>>(
                    stream: logService.logsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                            ),
                          ),
                        );
                      }

                      final logs = snapshot.data ?? [];
                      if (logs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                          child: Text(
                            'No logs yet. Use a feature to see history here.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 13,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: logs.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 1,
                        ),
                        itemBuilder: (context, i) {
                          return _LogTile(log: logs[i]);
                        },
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOG TILE
// ─────────────────────────────────────────────────────────────────────────────
class _LogTile extends StatelessWidget {
  final VisionLog log;
  const _LogTile({required this.log});

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$m';
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'Scene Description': return Icons.auto_awesome_rounded;
      case 'Text Reading': return Icons.text_fields_rounded;
      case 'Currency AI': return Icons.currency_exchange_rounded;
      case 'Face Match': return Icons.face_retouching_natural_rounded;
      default: return Icons.bolt_rounded;
    }
  }

  Color _colorFor(String name) {
    switch (name) {
      case 'Scene Description': return const Color(0xFF3B82F6);
      case 'Text Reading': return const Color(0xFF8B5CF6);
      case 'Currency AI': return const Color(0xFF06B6D4);
      case 'Face Match': return const Color(0xFF10B981);
      default: return AppColors.primary;
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _LogDetailSheet(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(log.featureName);
    return GestureDetector(
      onTap: () => _showDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconFor(log.featureName), color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.featureName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(log.usedAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOG DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _LogDetailSheet extends StatelessWidget {
  final VisionLog log;
  const _LogDetailSheet({required this.log});

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              log.featureName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(log.usedAt),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 24),

            // Image (if any)
            if (log.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  log.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: AppColors.surfaceContainer,
                    child: Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.white24, size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // AI Output
            if (log.aiOutput != null) ...[
              Text(
                'AI Output',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Text(
                  log.aiOutput!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ] else
              Text(
                'No output data recorded for this session.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
