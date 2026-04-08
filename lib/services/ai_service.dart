import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'ml_kit_service.dart';
import 'vision_log_service.dart';
import 'gemini_service.dart';


// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const String _kPrefAiMode = 'ai_mode'; // 'cloud' | 'offline'

// ─────────────────────────────────────────────────────────────────────────────
// AI RESULT
// ─────────────────────────────────────────────────────────────────────────────
class AiResult {
  final String featureName;
  final String output;
  final String? error;
  final int latencyMs;

  const AiResult({
    required this.featureName,
    required this.output,
    this.error,
    required this.latencyMs,
  });

  bool get isSuccess => error == null;
}

// ─────────────────────────────────────────────────────────────────────────────
// AI SERVICE — singleton
//
// Routing logic:
//  • Text Reading  → ML Kit (local OCR — fastest, most accurate for text)
//  • Scene / Currency / Face → Firebase Cloud Function (Gemini 1.5 Flash)
//
// The user NEVER needs an API key — the Gemini key lives encrypted in Firebase.
// ─────────────────────────────────────────────────────────────────────────────
class AiService extends ChangeNotifier {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  final FlutterTts _tts = FlutterTts();
  final MLKitService _mlKit = MLKitService();

  bool   _isBusy       = false;
  bool   _speaking     = false;
  String _aiMode       = 'cloud';
  String _activeEngine = 'Gemini AI';

  bool   get isBusy       => _isBusy;
  String get aiMode       => _aiMode;
  String get activeEngine => _activeEngine;

  // ── Startup ──────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kPrefAiMode) ?? 'cloud';

    // Only allow 'cloud' or 'offline'. Anything else (old values like 'auto',
    // 'local') gets reset to 'cloud' so Gemini is used by default.
    if (stored == 'cloud' || stored == 'offline') {
      _aiMode = stored;
    } else {
      _aiMode = 'cloud';
      await prefs.setString(_kPrefAiMode, 'cloud');
      debugPrint('[AI] Reset invalid aiMode "$stored" -> cloud');
    }

    _activeEngine = _aiMode == 'cloud' ? 'Gemini AI' : 'On-Device AI';

    // TTS setup
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.46);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => _speaking = false);

    debugPrint('[AI] Initialized — Mode: $_aiMode');
  }

  Future<void> setAiMode(String mode) async {
    _aiMode = mode;
    _activeEngine = mode == 'cloud' ? 'Gemini AI' : 'On-Device AI';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefAiMode, mode);
    notifyListeners();
  }

  // ── Frame capture from ESP32 port 81 ─────────────────────────────────────
  // Port 81 is the dedicated AI capture server — completely separate from the
  // MJPEG live stream on port 80, so they never block each other.
  Future<Uint8List?> captureFrameFromGlasses(String deviceIp) async {
    final url = Uri.parse('http://$deviceIp:81/capture');
    debugPrint('[AI] Capturing from: $url');

    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final resp = await http.get(url).timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
          debugPrint('[AI] Captured ${resp.bodyBytes.length} bytes (attempt $attempt)');
          return resp.bodyBytes;
        } else {
          debugPrint('[AI] Capture attempt $attempt failed. Status: ${resp.statusCode}');
        }
      } catch (e) {
        debugPrint('[AI] Capture HTTP error (attempt $attempt): $e');
      }

      if (attempt < 2) await Future.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  // ── Gemini 1.5 Flash via local Generative AI SDK ─────────────────────────
  Future<String> _callGemini({
    required Uint8List imageBytes,
    required String featureType,
  }) async {
    return await GeminiService().analyzeImage(
      imageBytes: imageBytes,
      featureType: featureType,
    );
  }


  // ── TTS ───────────────────────────────────────────────────────────────────
  Future<void> speak(String text) async {
    if (_speaking) await _tts.stop();
    _speaking = true;
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    _speaking = false;
    await _tts.stop();
  }

  // ── Public Feature Methods ────────────────────────────────────────────────
  Future<AiResult> describeScene({
    required Uint8List imageBytes,
    required VisionLogService logService,
  }) =>
      _run(
        featureName:  'Scene Description',
        featureType:  'scene',
        imageBytes:   imageBytes,
        logService:   logService,
        useGemini:    true,
      );

  Future<AiResult> readText({
    required Uint8List imageBytes,
    required VisionLogService logService,
  }) =>
      _run(
        featureName:  'Text Reading',
        featureType:  'text',
        imageBytes:   imageBytes,
        logService:   logService,
        useGemini:    false, // Always use local ML Kit OCR — it's more accurate
      );

  Future<AiResult> detectCurrency({
    required Uint8List imageBytes,
    required VisionLogService logService,
  }) =>
      _run(
        featureName:  'Currency AI',
        featureType:  'currency',
        imageBytes:   imageBytes,
        logService:   logService,
        useGemini:    true,
      );

  Future<AiResult> describeFace({
    required Uint8List imageBytes,
    required VisionLogService logService,
  }) =>
      _run(
        featureName:  'Face Match',
        featureType:  'face',
        imageBytes:   imageBytes,
        logService:   logService,
        useGemini:    true,
      );

  // ── Core Dispatcher ───────────────────────────────────────────────────────
  Future<AiResult> _run({
    required String featureName,
    required String featureType,
    required Uint8List imageBytes,
    required VisionLogService logService,
    required bool useGemini,
  }) async {
    if (_isBusy) {
      return const AiResult(
        featureName: 'Busy',
        output: 'Already processing. Please wait.',
        latencyMs: 0,
      );
    }

    _isBusy = true;
    notifyListeners();

    final sw   = Stopwatch()..start();
    String out = '';
    String? err;

    try {
      if (useGemini && _aiMode == 'cloud') {
        // ── Cloud path: Gemini 1.5 Flash via Firebase Function ──
        _activeEngine = 'Gemini AI';
        out = await _callGemini(imageBytes: imageBytes, featureType: featureType);
      } else {
        // ── Local path: ML Kit on-device (offline fallback or text OCR) ──
        _activeEngine = 'On-Device AI';
        final tmpFile = await _saveTmp(imageBytes);
        switch (featureType) {
          case 'text':
            out = await _mlKit.readText(tmpFile);
            break;
          case 'currency':
            out = await _mlKit.detectCurrency(tmpFile);
            break;
          default:
            out = await _mlKit.describeScene(tmpFile);
        }
      }

      await speak(out);
      await logService.addLog(featureName: featureName, aiOutput: out);
    } catch (e) {
      err = e.toString();
      debugPrint('[AI] Error in $_activeEngine for $featureName: $e');
      // Friendly error message that gets spoken aloud
      final spoken = 'Sorry, analysis failed. Please check your connection and try again.';
      await speak(spoken);
    } finally {
      sw.stop();
      _isBusy = false;
      notifyListeners();
    }

    return AiResult(
      featureName: featureName,
      output:      err != null ? 'Analysis failed. Please try again.' : out,
      error:       err,
      latencyMs:   sw.elapsedMilliseconds,
    );
  }

  Future<File> _saveTmp(Uint8List bytes) async {
    final path = '${Directory.systemTemp.path}/ai_frame.jpg';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }
}
