import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),

          const Text(
            "Guide",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            "User Guide",
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 40),

          _buildGuideCard(
            icon: Icons.touch_app,
            title: "Single Press",
            description: "Quick tap the button on the temple to trigger the mapped action (default: Describe Scene).",
          ),

          const SizedBox(height: 16),

          _buildGuideCard(
            icon: Icons.double_arrow,
            title: "Double Press",
            description: "Double tap the button to trigger your secondary action (default: Read Text / OCR).",
          ),

          const SizedBox(height: 16),

          _buildGuideCard(
            icon: Icons.pan_tool,
            title: "Long Press (3s)",
            description: "Press and hold for 3 seconds to power on/off the glasses or cancel listening.",
          ),

          const SizedBox(height: 16),

          _buildGuideCard(
            icon: Icons.nightlight_round,
            title: "Night Vision",
            description: "Automatically activates when ambient light drops below 10 Lux. IR LEDs will turn on.",
          ),

          const SizedBox(height: 16),

          _buildGuideCard(
            icon: Icons.bluetooth,
            title: "Connectivity",
            description: "BLE is used for commands and status. Wi-Fi is used for uploading images/video to the cloud.",
          ),

          const SizedBox(height: 16),

          _buildGuideCard(
            icon: Icons.warning_amber_rounded,
            title: "Safety",
            description: "If IR LEDs exceed 40°C, night vision auto-disables. You'll get an alert on your phone.",
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildGuideCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A182E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    height: 1.4,
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
