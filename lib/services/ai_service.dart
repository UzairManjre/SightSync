import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'vision_log_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURATION KEYS
// ─────────────────────────────────────────────────────────────────────────────
const String _kPrefOllamaHost = 'ai_ollama_host';
const String _kDefaultHost    = '192.168.1.12'; // Mac's LAN IP running Ollama
const int    _kOllamaPort     = 11434;
const String _kModel          = 'qwen3-vl:2b';

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
// ─────────────────────────────────────────────────────────────────────────────
class AiService extends ChangeNotifier {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isBusy   = false;
  bool _speaking = false;
  String _ollamaHost = _kDefaultHost;

  bool   get isBusy     => _isBusy;
  String get ollamaHost => _ollamaHost;

  // ── Startup ────────────────────────────────────────────────────────────────
  Future<void> init() async {
    // Load persisted host
    final prefs = await SharedPreferences.getInstance();
    _ollamaHost = prefs.getString(_kPrefOllamaHost) ?? _kDefaultHost;

    // TTS setup
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.46);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => _speaking = false);

    debugPrint('[AI] Ready — Ollama @ $_ollamaHost:$_kOllamaPort — model: $_kModel');
  }

  /// Update the Ollama host at runtime and persist it.
  Future<void> setOllamaHost(String host) async {
    _ollamaHost = host.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefOllamaHost, _ollamaHost);
    notifyListeners();
    debugPrint('[AI] Ollama host updated → $_ollamaHost');
  }

  /// Quick connectivity test — returns true if Ollama responds.
  Future<bool> testConnection() async {
    try {
      final url = Uri.parse('http://$_ollamaHost:$_kOllamaPort/api/version');
      final resp = await http.get(url).timeout(const Duration(seconds: 4));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Core Ollama vision call ────────────────────────────────────────────────
  Future<String> _callVision({
    required Uint8List imageBytes,
    required String systemPrompt,
    required String userPrompt,
    int timeoutSeconds = 28,
  }) async {
    final url = Uri.parse('http://$_ollamaHost:$_kOllamaPort/api/chat');
    final b64  = base64Encode(imageBytes);

    final body = jsonEncode({
      'model':  _kModel,
      'think':  false,        // ← kills Qwen3 chain-of-thought tokens
      'stream': false,
      'messages': [
        {
          'role':    'system',
          'content': systemPrompt,
        },
        {
          'role':    'user',
          'content': userPrompt,
          'images':  [b64],
        },
      ],
      'options': {
        'temperature':    0.1,   // near-deterministic
        'top_p':          0.8,   // narrow candidate pool
        'repeat_penalty': 1.1,   // stops looping
        'num_predict':    180,   // hard output length cap
      },
    });

    final resp = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(Duration(seconds: timeoutSeconds));

    if (resp.statusCode != 200) {
      throw Exception('Ollama HTTP ${resp.statusCode}: ${resp.body}');
    }

    final data    = jsonDecode(resp.body) as Map<String, dynamic>;
    final content = (data['message']?['content'] as String? ?? '').trim();

    // Belt-and-suspenders: strip any leaked <think>…</think> tokens
    return _strip(content);
  }

  String _strip(String raw) =>
      raw.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '').trim();

  // ── Frame capture from ESP32 /capture endpoint ─────────────────────────────
  Future<Uint8List?> captureFrameFromGlasses(String deviceIp) async {
    try {
      final url  = Uri.parse('http://$deviceIp/capture');
      final resp = await http.get(url).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        return resp.bodyBytes;
      }
    } catch (e) {
      debugPrint('[AI] Frame capture failed: $e');
    }
    return null;
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

  // ── FEATURES ──────────────────────────────────────────────────────────────
  static const _systemBase =
      'You are a concise assistive vision AI for a visually impaired person. '
      'Respond ONLY with factual observations based on what you see. '
      'Never speculate, invent detail, or add opinions. '
      'Maximum 2 short sentences.';

  Future<AiResult> describeScene({
    required Uint8List imageBytes,
    required VisionLogService logService,
  }) =>
      _run(
        featureName:  'Scene Description',
        imageBytes:   imageBytes,
        logService:   logService,
        systemPrompt: _systemBase,
        userPrompt:
            'Describe what you can see. '
            'Name any people, objects, text signs, or hazards.',
      );

  Future<AiResult> readText({
    required Uint8List imageBytes,
    required VisionLogService logService,
  }) =>
      _run(
        featureName:  'Text Reading',
        imageBytes:   imageBytes,
        logService:   logService,
        systemPrompt: _systemBase,
        userPrompt:
            'Read and transcribe every word of visible text exactly. '
            'If there is no text say: No text found.',
      );

  Future<AiResult> detectCurrency({
    required Uint8List imageBytes,
    required VisionLogService logService,
  }) =>
      _run(
        featureName:  'Currency AI',
        imageBytes:   imageBytes,
        logService:   logService,
        systemPrompt: _systemBase,
        userPrompt:
            'Identify any currency notes or coins. '
            'State denomination and currency name. '
            'If none visible say: No currency detected.',
      );

  Future<AiResult> describeFace({
    required Uint8List imageBytes,
    required VisionLogService logService,
  }) =>
      _run(
        featureName:  'Face Match',
        imageBytes:   imageBytes,
        logService:   logService,
        systemPrompt: _systemBase,
        userPrompt:
            'Describe any person you can see: approximate age, gender, '
            'and distinguishing features. '
            'If no person is visible say: No person detected.',
      );

  // ── Internal runner ───────────────────────────────────────────────────────
  Future<AiResult> _run({
    required String featureName,
    required Uint8List imageBytes,
    required VisionLogService logService,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (_isBusy) {
      return const AiResult(
        featureName: 'Busy',
        output: 'Another feature is already processing. Please wait.',
        latencyMs: 0,
      );
    }

    _isBusy = true;
    notifyListeners();

    final sw     = Stopwatch()..start();
    String  out  = '';
    String? err;

    try {
      out = await _callVision(
        imageBytes:   imageBytes,
        systemPrompt: systemPrompt,
        userPrompt:   userPrompt,
      );
      if (out.isEmpty) out = 'No response received from AI.';

      await speak(out);
      await logService.addLog(featureName: featureName, aiOutput: out);
    } on TimeoutException {
      err = 'AI timed out. Check that Ollama is reachable on $_ollamaHost.';
      await speak('Sorry, the AI timed out. Please check your network.');
    } catch (e) {
      err = e.toString();
      debugPrint('[AI] $_featureName error: $e');
      await speak('Sorry, the AI encountered an error.');
    } finally {
      sw.stop();
      _isBusy = false;
      notifyListeners();
    }

    return AiResult(
      featureName: featureName,
      output:      err ?? out,
      error:       err,
      latencyMs:   sw.elapsedMilliseconds,
    );
  }

  String get _featureName => 'AiService'; // internal label
}
