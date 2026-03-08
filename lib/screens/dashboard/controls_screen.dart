import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class ControlsScreen extends StatelessWidget {
  final bool isListening;
  final VoidCallback onToggleListening;
  final bool isLoading;
  final String singlePressAction;
  final String doublePressAction;
  final String longPressAction;
  final Function(String key, String value) onUpdateMapping;

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

  static const Map<String, String> _actionLabels = {
    'describe_scene': 'Describe Scene',
    'read_text': 'Read Text (OCR)',
    'navigation': 'Navigation',
    'voice_assistant': 'Voice Assistant',
    'off': 'Off',
  };

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Mic Toggle
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onToggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isListening ? AppColors.success : Colors.white24,
                    width: 2,
                  ),
                  color: isListening
                      ? AppColors.success.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  boxShadow: isListening
                      ? [BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 15)]
                      : [],
                ),
                child: Icon(
                  isListening ? Icons.mic : Icons.graphic_eq,
                  color: isListening ? AppColors.success : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "Controls",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            "Button Mapping",
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 40),

          // Single Press
          _buildMappingCard(
            icon: Icons.touch_app,
            title: "Single Press",
            currentValue: singlePressAction,
            configKey: 'single_press_action',
          ),

          const SizedBox(height: 16),

          // Double Press
          _buildMappingCard(
            icon: Icons.double_arrow,
            title: "Double Press",
            currentValue: doublePressAction,
            configKey: 'double_press_action',
          ),

          const SizedBox(height: 16),

          // Long Press
          _buildMappingCard(
            icon: Icons.pan_tool,
            title: "Long Press",
            currentValue: longPressAction,
            configKey: 'long_press_action',
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildMappingCard({
    required IconData icon,
    required String title,
    required String currentValue,
    required String configKey,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A182E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _actionLabels[currentValue] ?? currentValue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
            color: const Color(0xFF1E1E2E),
            onSelected: (value) => onUpdateMapping(configKey, value),
            itemBuilder: (_) => _actionLabels.entries
                .map((e) => PopupMenuItem(
                      value: e.key,
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: e.key == currentValue
                              ? AppColors.primaryBlue
                              : Colors.white,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
