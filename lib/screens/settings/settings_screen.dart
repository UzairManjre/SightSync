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
                    const _SectionLabel(text: 'SMART AI ENGINE'),
                    const SizedBox(height: 12),
                    const _AiEngineConfigTile(),
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
// HYBRID AI CONFIGURATOR TILE
// ─────────────────────────────────────────────────────────────────────────────
class _AiEngineConfigTile extends StatefulWidget {
  const _AiEngineConfigTile();

  @override
  State<_AiEngineConfigTile> createState() => _AiEngineConfigTileState();
}

class _AiEngineConfigTileState extends State<_AiEngineConfigTile> {

  void _editGeminiKey() async {
    final ai = context.read<AiService>();
    final ctrl = TextEditingController(text: ai.geminiKey);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Gemini API Key', style: AppTheme.h3Style),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Used for high-resolution cloud analysis. Get your key at aistudio.google.com',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: AppTheme.inputDecoration('Paste API Key here'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ai.setGeminiKey(result);
    }
  }

  void _editOllamaHost() async {
    final ai = context.read<AiService>();
    final ctrl = TextEditingController(text: ai.ollamaHost);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ollama Host', style: AppTheme.h3Style),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: AppTheme.inputDecoration('e.g. 192.168.1.12'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save')),
        ],
      ),
    );

    if (result != null) {
      await ai.setOllamaHost(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiService>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(opacity: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'INTEGRATED AI',
                  style: TextStyle(
                    color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w900, letterSpacing: 1.5,
                  ),
                ),
              ),
              _ModeBadge(mode: ai.aiMode),
            ],
          ),
          const SizedBox(height: 24),
          
          // MODE SELECTOR
          const _SubLabel(text: 'INTELLIGENCE MODE'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ModeChip(label: 'AUTO', value: 'auto', current: ai.aiMode),
                _ModeChip(label: 'CLOUD', value: 'cloud', current: ai.aiMode),
                _ModeChip(label: 'OFFLINE', value: 'offline', current: ai.aiMode),
                _ModeChip(label: 'LOCAL', value: 'local', current: ai.aiMode),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          // GEMINI CONFIG (Always show for cloud/auto)
          if (ai.aiMode == 'auto' || ai.aiMode == 'cloud') ...[
            _ConfigRow(
              label: 'GEMINI CLOUD',
              value: ai.geminiKey.isEmpty ? 'NOT SET' : '••••••••••••',
              icon: Icons.cloud_done_rounded,
              onTap: _editGeminiKey,
            ),
            const SizedBox(height: 16),
          ],

          // OLLAMA CONFIG (Show for local)
          if (ai.aiMode == 'local' || ai.aiMode == 'auto') ...[
            _ConfigRow(
              label: 'OLLAMA SERVER',
              value: ai.ollamaHost,
              icon: Icons.developer_board_rounded,
              onTap: _editOllamaHost,
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label, value, current;
  const _ModeChip({required this.label, required this.value, required this.current});

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return GestureDetector(
      onTap: () => context.read<AiService>().setAiMode(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.primary : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white70,
            fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final VoidCallback onTap;
  const _ConfigRow({required this.label, required this.value, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.w800)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final String mode;
  const _ModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Text(
        mode.toUpperCase(),
        style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  final String text;
  const _SubLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
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
