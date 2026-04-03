import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widgets/ambient_background.dart';

class ControlsScreen extends StatelessWidget {
  final bool isListening;
  final VoidCallback onToggleListening;
  final bool isLoading;
  final String singlePressAction;
  final String doublePressAction;
  final String longPressAction;
  final Future<void> Function(String key, String value) onUpdateMapping;

  const ControlsScreen({
    super.key,
    required this.isListening,
    required this.onToggleListening,
    required this.isLoading,
    required this.singlePressAction,
    required this.doublePressAction,
    required this.longPressAction,
    required this.onUpdateMapping,
  });

  @override
  Widget build(BuildContext context) {
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
                      'PROTOCOLS',
                      style: TextStyle(
                        color: Colors.white, fontSize: 24,
                        fontWeight: FontWeight.w900, fontFamily: 'SpaceGrotesk',
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'CONFIGURE HARDWARE INPUTS AND AI VOICE NARRATION.',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // ── Button Mappings ─────────────────────
                    const _SectionLabel(text: 'BUTTON MAPPING CONFIG'),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                    else ...[
                      _MappingTile(
                        icon: Icons.touch_app_rounded,
                        label: 'SINGLE PRESS',
                        current: singlePressAction,
                        onChanged: (v) => onUpdateMapping('single_press_action', v),
                      ),
                      const SizedBox(height: 12),
                      _MappingTile(
                        icon: Icons.ads_click_rounded,
                        label: 'DOUBLE PRESS',
                        current: doublePressAction,
                        onChanged: (v) => onUpdateMapping('double_press_action', v),
                      ),
                      const SizedBox(height: 12),
                      _MappingTile(
                        icon: Icons.gesture_rounded,
                        label: 'LONG PRESS',
                        current: longPressAction,
                        onChanged: (v) => onUpdateMapping('long_press_action', v),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // ── Audio Settings ──────────────────────
                    const _SectionLabel(text: 'AUDIO & HAPTIC FEEDBACK'),
                    const SizedBox(height: 16),
                    _SliderTile(label: 'VOICE VOLUME', value: 0.7, icon: Icons.volume_up_rounded),
                    const SizedBox(height: 12),
                    _SliderTile(label: 'NARRATION SPEED', value: 0.5, icon: Icons.speed_rounded),
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: AppTheme.glassDecoration(opacity: 0.05, radius: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.record_voice_over_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('AI VOICE MODEL',
                                      style: TextStyle(color: AppColors.textTertiary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                  Text('SAMANTHA PRO v2',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                          Icon(Icons.tune_rounded, color: AppColors.primary.withOpacity(0.5), size: 20),
                        ],
                      ),
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

const _actionOptions = {
  'describe_scene': 'Describe Scene',
  'read_text':      'Read Text',
  'identify_color': 'Identify Colour',
  'off':            'Disabled',
};

class _MappingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String current;
  final ValueChanged<String> onChanged;
  const _MappingTile({required this.icon, required this.label, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: AppTheme.glassDecoration(opacity: 0.05, radius: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 16),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5, fontFamily: 'SpaceGrotesk')),
            ],
          ),
          DropdownButton<String>(
            value: current,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'SpaceGrotesk'),
            underline: const SizedBox(),
            elevation: 16,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 22),
            items: _actionOptions.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.toUpperCase())))
                .toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatefulWidget {
  final String label;
  final double value;
  final IconData icon;
  const _SliderTile({required this.label, required this.value, required this.icon});

  @override
  State<_SliderTile> createState() => _SliderTileState();
}

class _SliderTileState extends State<_SliderTile> {
  late double _v;
  @override void initState() { super.initState(); _v = widget.value; }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
      decoration: AppTheme.glassDecoration(opacity: 0.05, radius: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: AppColors.primary, size: 18),
                  const SizedBox(width: 16),
                  Text(widget.label,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5, fontFamily: 'SpaceGrotesk')),
                ],
              ),
              Text('${(_v * 100).round()}%',
                  style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'SpaceGrotesk')),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.1),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, elevation: 4),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(value: _v, onChanged: (v) => setState(() => _v = v)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        fontFamily: 'SpaceGrotesk',
      ),
    );
  }
}
