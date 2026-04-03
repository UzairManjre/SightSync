import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService extends ChangeNotifier {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  // Custom UUIDs (SightSync Specific)
  final String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  final String commandCharUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  final String eventCharUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  final String ipCharUuid = "6E400004-B5A3-F393-E0A9-E50E24DCCA9E";
  
  // Standard BLE Battery Service UUIDs
  final String batteryServiceUuid = "180F";
  final String batteryLevelCharUuid = "2A19";

  // Dual Device Support
  BluetoothDevice? leftDevice;
  BluetoothDevice? rightDevice;

  BluetoothCharacteristic? leftCommandChar;
  BluetoothCharacteristic? rightCommandChar;
  BluetoothCharacteristic? leftEventChar;
  BluetoothCharacteristic? rightEventChar;
  BluetoothCharacteristic? leftBatteryChar;
  BluetoothCharacteristic? rightBatteryChar;

  // Camera Settings
  String? rightDeviceIp;
  String? leftDeviceIp;

  // Helper: IP from whichever side is available
  String? get activeDeviceIp => rightDeviceIp ?? leftDeviceIp;

  // Stream for Events (Consolidated from both arms)
  final StreamController<Map<String, dynamic>> _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  // Stream for Battery Levels
  final StreamController<Map<String, int>> _batteryController = StreamController<Map<String, int>>.broadcast();
  Stream<Map<String, int>> get batteryStream => _batteryController.stream;

  // Stream for RSSI (Signal)
  final StreamController<Map<String, int>> _rssiController = StreamController<Map<String, int>>.broadcast();
  Stream<Map<String, int>> get rssiStream => _rssiController.stream;

  // Stream for Thermal Status
  final StreamController<Map<String, String>> _thermalController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get thermalStream => _thermalController.stream;

  Timer? _rssiTimer;

  Future<void> init() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  Future<void> startScan() async {
    // Wait for Bluetooth to actually be ON before scanning (critical for iOS)
    await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;
    
    // Now start the scan safely
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      print("Failed to start scan: $e");
    }
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connectLeft(BluetoothDevice device) async {
    await device.connect();
    leftDevice = device;
    notifyListeners(); // rebuild UI immediately on connect
    await _discoverServices(device, "left");
  }

  Future<void> connectRight(BluetoothDevice device) async {
    await device.connect();
    rightDevice = device;
    notifyListeners(); // rebuild UI immediately on connect
    await _discoverServices(device, "right");
  }

  Future<void> disconnect() async {
    if (leftDevice != null) await leftDevice!.disconnect();
    if (rightDevice != null) await rightDevice!.disconnect();
    leftDevice  = null;
    rightDevice = null;
    leftCommandChar = null;
    rightCommandChar = null;
    leftEventChar = null;
    rightEventChar = null;
    leftBatteryChar = null;
    rightBatteryChar = null;
    rightDeviceIp = null;
    leftDeviceIp = null;
    _stopRssiPolling();
    notifyListeners();
  }

  void _startRssiPolling() {
    _rssiTimer?.cancel();
    _rssiTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (leftDevice != null) {
        final rssi = await leftDevice!.readRssi();
        _rssiController.add({"left": rssi});
      }
      if (rightDevice != null) {
        final rssi = await rightDevice!.readRssi();
        _rssiController.add({"right": rssi});
      }
    });
  }

  void _stopRssiPolling() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
  }

  Future<void> _discoverServices(BluetoothDevice device, String side) async {
    List<BluetoothService> services = await device.discoverServices();
    
    for (var service in services) {
      String currentUuid = service.uuid.toString().toUpperCase();

      if (currentUuid == serviceUuid) {
        for (var characteristic in service.characteristics) {
          String uuid = characteristic.uuid.toString().toUpperCase();
          if (uuid == commandCharUuid) {
            if (side == "left") leftCommandChar = characteristic;
            else rightCommandChar = characteristic;
          } else if (uuid == eventCharUuid) {
            if (side == "left") {
              leftEventChar = characteristic;
              await _setupNotifications(leftEventChar!, "left");
            } else {
              rightEventChar = characteristic;
              await _setupNotifications(rightEventChar!, "right");
            }
          } else if (uuid == ipCharUuid) {
            // Support IP on whichever arm is actually connected
            await characteristic.setNotifyValue(true);
            
            // Initial read
            List<int> initialVal = await characteristic.read();
            if (initialVal.isNotEmpty) {
              final ip = utf8.decode(initialVal).trim();
              if (side == "right") rightDeviceIp = ip;
              else leftDeviceIp = ip;
              notifyListeners();
            }

            // Listen for updates
            characteristic.lastValueStream.listen((val) {
              if (val.isNotEmpty) {
                final ip = utf8.decode(val).trim();
                if (side == "right") rightDeviceIp = ip;
                else leftDeviceIp = ip;
                debugPrint("--- UPDATED $side IP: $ip ---");
                notifyListeners();
              }
            });
          }
        }
      }
      
      if (currentUuid.contains(batteryServiceUuid)) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase().contains(batteryLevelCharUuid)) {
            if (side == "left") {
              leftBatteryChar = characteristic;
              await _setupBatteryNotifications(leftBatteryChar!, "left");
            } else {
              rightBatteryChar = characteristic;
              await _setupBatteryNotifications(rightBatteryChar!, "right");
            }
          }
        }
      }
    }
    _startRssiPolling();
  }

  Future<void> _setupNotifications(BluetoothCharacteristic characteristic, String side) async {
    await characteristic.setNotifyValue(true);
    characteristic.lastValueStream.listen((value) {
      if (value.isNotEmpty) {
        _handleEventCode(value[0], side);
      }
    });
  }

  Future<void> _setupBatteryNotifications(BluetoothCharacteristic characteristic, String side) async {
    await characteristic.setNotifyValue(true);
    List<int> initialVal = await characteristic.read();
    if (initialVal.isNotEmpty) {
      _batteryController.add({side: initialVal[0]});
    }
    characteristic.lastValueStream.listen((value) {
      if (value.isNotEmpty) {
        _batteryController.add({side: value[0]});
      }
    });
  }

  void _handleEventCode(int code, String side) {
    String message = "";
    switch (code) {
      case 0x01: message = "Single Press"; break;
      case 0x02: message = "Double Press"; break;
      case 0x03: message = "Long Press Start"; break;
      case 0x04: message = "Long Press End"; break;
      case 0x10: message = "Low Battery"; break;
      case 0x11: 
        message = "Thermal Warning"; 
        _thermalController.add({side: "HOT"});
        break;
      default: message = "Event: $code";
    }
    if (code != 0x11) _thermalController.add({side: "COOL"}); // Clear warning on other events
    _eventController.add({"side": side, "message": message, "code": code});
  }

  Future<void> writeCommand(Map<String, dynamic> command, {String? side}) async {
    String jsonString = jsonEncode(command);
    List<int> bytes = utf8.encode(jsonString);
    if (side == "left" || side == null) {
      if (leftCommandChar != null) await leftCommandChar!.write(bytes);
    }
    if (side == "right" || side == null) {
      if (rightCommandChar != null) await rightCommandChar!.write(bytes);
    }
  }
}