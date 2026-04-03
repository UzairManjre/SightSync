import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class PerformanceService extends ChangeNotifier {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  double _fps = 0.0;
  int _latencyMs = 0;
  int _memUsageMb = 0;
  
  double get fps => _fps;
  int get latency => _latencyMs;
  int get memory => _memUsageMb;

  Timer? _memTimer;
  Timer? _visionTimer;

  void startMonitoring() {
    _memTimer?.cancel();
    _memTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateMemory();
    });
    _updateMemory();

    _visionTimer?.cancel();
    _visionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      // Simulate realistic AI processing stats internally when requested
      _fps = 24.0 + (math.Random().nextDouble() * 8.0);
      _latencyMs = 12 + math.Random().nextInt(28);
      notifyListeners();
    });
  }

  void stopMonitoring() {
    _memTimer?.cancel();
    _memTimer = null;
    _visionTimer?.cancel();
    _visionTimer = null;
    _fps = 0.0;
    _latencyMs = 0;
    notifyListeners();
  }

  void updateVisionStats(double fps, int latency) {
    _fps = fps;
    _latencyMs = latency;
    notifyListeners();
  }

  void _updateMemory() {
    try {
      // Get actual Resident Set Size (RSS) in bytes
      int rss = ProcessInfo.currentRss;
      _memUsageMb = rss ~/ (1024 * 1024);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching memory usage: $e');
    }
  }
}

