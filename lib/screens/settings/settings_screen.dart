import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../utils/theme.dart';
import '../auth/splash_screen.dart';
import '../../widgets/ambient_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthService>();
    final user  = auth.currentUser;

    return Scaffold(
      body: AmbientBackground(
        isPremium: true,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'SETTINGS',
                      style: TextStyle(
                        color: Colors.white, fontSize: 24,
                        fontWeight: FontWeight.w900, fontFamily: 'SpaceGrotesk',
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // ── Profile Card ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.glassDecoration(opacity: 0.1),
                      child: Row(
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: const BoxDecoration(
                              gradient: AppGradients.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: AppColors.primary, blurRadius: 15, spreadRadius: -5),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.displayName ?? 'User ID: 004',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? 'AUTHORIZED OPERATOR',
                                  style: const TextStyle(
                                    color: AppColors.textTertiary, fontSize: 11,
                                    fontWeight: FontWeight.w700, letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Device Section ────────────────────────────
                    const _SectionLabel(text: 'HARDWARE & CONNECTIVITY'),
                    const SizedBox(height: 12),
                    _SettingsTile(
                      icon: Icons.system_update_outlined,
                      title: 'Firmware Update',
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.wifi_outlined,
                      title: 'Network Config',
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.link_off_rounded,
                      title: 'Unpair Node',
                      onTap: () {},
                    ),
                    const SizedBox(height: 32),

                    // ── General Section ───────────────────────────
                    const _SectionLabel(text: 'SYSTEM PREFERENCES'),
                    const SizedBox(height: 12),
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Telemetry Alerts',
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Protocol Support',
                      onTap: () {},
                    ),
                    const SizedBox(height: 32),

                    // ── AI Engine Section ─────────────────────────
                    const _SectionLabel(text: 'AI ENGINE'),
                    const SizedBox(height: 12),
                    _OllamaHostTile(),
                    const SizedBox(height: 32),

                    // ── Account Section ───────────────────────────
                    const _SectionLabel(text: 'SECURITY PROTOCOL'),
                    const SizedBox(height: 12),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'Terminate Session',
                      isDestructive: true,
                      onTap: () async {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const SplashScreen()),
                            (r) => false,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.delete_forever_rounded,
                      title: 'Purge User Data',
                      isDestructive: true,
                      onTap: () {},
                    ),
                    const SizedBox(height: 60),
                  ],
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
// OLLAMA HOST CONFIGURATOR TILE
// ─────────────────────────────────────────────────────────────────────────────
class _OllamaHostTile extends StatefulWidget {
  @override
  State<_OllamaHostTile> createState() => _OllamaHostTileState();
}

class _OllamaHostTileState extends State<_OllamaHostTile> {
  bool _testing = false;
  bool? _lastResult;

  Future<void> _editHost() async {
    final ai  = AiService();
    final ctrl = TextEditingController(text: ai.ollamaHost);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ollama Host IP',
          style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the local IP of the machine running Ollama.\n'
              'Make sure you launched it with:\nOLLAMA_HOST=0.0.0.0 ollama serve',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13, height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '192.168.1.x',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ai.setOllamaHost(result);
      setState(() => _lastResult = null);
    }
  }

  Future<void> _testConnection() async {
    setState(() { _testing = true; _lastResult = null; });
    final ok = await AiService().testConnection();
    setState(() { _testing = false; _lastResult = ok; });
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();

    Color statusColor = Colors.white38;
    IconData statusIcon = Icons.radio_button_unchecked;
    if (_lastResult == true)  { statusColor = AppColors.success; statusIcon = Icons.check_circle_rounded; }
    if (_lastResult == false) { statusColor = AppColors.error;   statusIcon = Icons.cancel_rounded; }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(opacity: 0.05, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OLLAMA AI SERVER',
                      style: TextStyle(
                        color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w900, letterSpacing: 1,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${ai.ollamaHost}:11434  ·  qwen3-vl:2b',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (_testing)
                const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              else
                Icon(statusIcon, color: statusColor, size: 18),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniButton(
                  label: 'CHANGE HOST',
                  icon: Icons.edit_rounded,
                  onTap: _editHost,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniButton(
                  label: 'TEST',
                  icon: Icons.wifi_tethering_rounded,
                  onTap: _testing ? null : _testConnection,
                  primary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  const _MiniButton({required this.label, required this.icon, this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: primary
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primary
                ? AppColors.primary.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14,
                color: primary ? AppColors.primary : Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: primary ? AppColors.primary : Colors.white.withValues(alpha: 0.6),
                fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: AppTheme.glassDecoration(opacity: 0.05, radius: 20),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary, size: 22),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: color, 
                  fontSize: 12, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textTertiary.withOpacity(0.3), size: 14),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          fontFamily: 'SpaceGrotesk',
        ),
      ),
    );
  }
}
