import 'package:flutter/material.dart';
import '../utils/theme.dart';

class FeatureModel {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String interaction;
  final String category;
  final String howToUse;

  const FeatureModel({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.interaction,
    required this.howToUse,
    this.category = 'AI CAPABILITIES',
  });
}

class FeatureRegistry {
  static const List<FeatureModel> allFeatures = [
    FeatureModel(
      icon: Icons.nightlight_round,
      title: 'Night Vision',
      description: 'Thermal infrared visibility enhancement. See clearly in total darkness via IR optics.',
      color: AppColors.primary,
      interaction: 'Auto Toggle',
      category: 'HARDWARE & OPTICS',
      howToUse: 'The system automatically activates IR LEDs when light levels drop below 10 lux. You can also force toggle it via the HUD button.',
    ),
    FeatureModel(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Chatbot',
      description: 'Voice-activated AI assistant for navigation, info, and system control.',
      color: AppColors.accent,
      interaction: 'Voice Sync',
      howToUse: "Triple-tap the primary button or say 'Sync' to wake the AI. Ask questions about your surroundings or system status.",
    ),
    FeatureModel(
      icon: Icons.sos_rounded,
      title: 'Emergency SOS',
      description: 'Broadcasts live GPS and video to emergency contacts instantly.',
      color: AppColors.error,
      interaction: '3s Hold',
      category: 'SAFETY PROTOCOL',
      howToUse: 'In an emergency, press and hold the primary module button for 3 seconds. The HUD will flash red and your contacts will receive your live location.',
    ),
    FeatureModel(
      icon: Icons.landscape_rounded,
      title: 'Scene Describe',
      description: 'Generates a rich, contextual narration of your current surroundings.',
      color: AppColors.success,
      interaction: 'Long Press',
      howToUse: 'Perform a 1-second long press on the primary button. The AI will scan the entire field of view and describe the scene in your ear.',
    ),
    FeatureModel(
      icon: Icons.radar_rounded,
      title: 'Collision Avoid',
      description: 'Real-time proximity alerts using ToF sensors and spatial audio beeps.',
      color: AppColors.primary,
      interaction: 'Auto Active',
      category: 'SAFETY PROTOCOL',
      howToUse: 'Collision avoidance is always active. You will hear faster haptic pulses in the arm and higher pitched beeps as you get closer to an object.',
    ),
    FeatureModel(
      icon: Icons.text_fields_rounded,
      title: 'Text Reading',
      description: 'High-speed OCR to read signs, menus, warnings, and documents aloud.',
      color: AppColors.accent,
      interaction: 'Single Press',
      howToUse: 'Point the camera toward any text and press the primary button once. The system will start reading the text immediately.',
    ),
    FeatureModel(
      icon: Icons.monetization_on_outlined,
      title: 'Currency AI',
      description: 'Identification of bill denominations for safe and secure transactions.',
      color: AppColors.success,
      interaction: 'Auto Scan',
      howToUse: 'Hold a banknote about 6 inches from the camera. The system will detect and announce the currency value and validity.',
    ),
    FeatureModel(
      icon: Icons.video_call_rounded,
      title: 'Video Calling',
      description: 'Live hands-free streaming to a remote human assistant for guidance.',
      color: AppColors.primary,
      interaction: 'Remote Sync',
      howToUse: 'Initiate a call from the Dashboard. A remote assistant can see your live feed and guide you through complex environments via audio.',
    ),
    FeatureModel(
      icon: Icons.face_retouching_natural_rounded,
      title: 'Face Match',
      description: 'Identifies and alerts you when saved friends or family members are in view.',
      color: AppColors.accent,
      interaction: 'Auto Alert',
      howToUse: "When a known face enters the frame, the system will whisper 'Friend: [Name]' into your bone-conduction earpiece.",
    ),
  ];
}
