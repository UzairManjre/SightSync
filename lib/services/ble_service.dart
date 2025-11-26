import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  // Custom UUIDs (SightSync Specific)
  final String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  final String commandCharUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  final String eventCharUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  
  // Standard BLE Battery Service UUIDs
  final String batteryServiceUuid = "180F";
  final String batteryLevelCharUuid = "2A19";

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? commandChar;
  BluetoothCharacteristic? eventChar;
  BluetoothCharacteristic? batteryChar; // New

  // Stream for Events (Button presses, Thermal warnings)
  final StreamController<String> _eventController = StreamController<String>.broadcast();
  Stream<String> get eventStream => _eventController.stream;

  // Stream for Battery Level (New)
  final StreamController<int> _batteryController = StreamController<int>.broadcast();
  Stream<int> get batteryStream => _batteryController.stream;

  // Initial Permissions Check
  Future<void> init() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  Future<void> startScan() async {
    // Scanning for both our Custom Service AND Battery Service devices
    await FlutterBluePlus.startScan(
      // withServices: [Guid(serviceUuid)], // Filter removed for broader compatibility
      timeout: const Duration(seconds: 15),
    );
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;
    await _discoverServices(device);
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      commandChar = null;
      eventChar = null;
      batteryChar = null;
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    
    for (var service in services) {
      String currentUuid = service.uuid.toString().toUpperCase();

      // 1. Setup Custom Service
      if (currentUuid == serviceUuid) {
        for (var characteristic in service.characteristics) {
          String uuid = characteristic.uuid.toString().toUpperCase();
          if (uuid == commandCharUuid) {
            commandChar = characteristic;
          } else if (uuid == eventCharUuid) {
            eventChar = characteristic;
            await _setupNotifications(eventChar!);
          }
        }
      }
      
      // 2. Setup Battery Service (Standard 0x180F)
      // Note: FlutterBluePlus might return 128-bit UUID, so we check 'contains' or exact match
      if (currentUuid.contains(batteryServiceUuid)) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase().contains(batteryLevelCharUuid)) {
            batteryChar = characteristic;
            await _setupBatteryNotifications(batteryChar!);
          }
        }
      }
    }
  }

  // Handle Custom Events (Buttons, Thermal)
  Future<void> _setupNotifications(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    characteristic.lastValueStream.listen((value) {
      if (value.isNotEmpty) {
        int code = value[0];
        _handleEventCode(code);
      }
    });
  }

  // Handle Battery Updates
  Future<void> _setupBatteryNotifications(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    // Read initial value
    List<int> initialVal = await characteristic.read();
    if (initialVal.isNotEmpty) {
      _batteryController.add(initialVal[0]);
    }
    
    // Listen for changes
    characteristic.lastValueStream.listen((value) {
      if (value.isNotEmpty) {
        _batteryController.add(value[0]); // The first byte is the percentage (0-100)
      }
    });
  }

  void _handleEventCode(int code) {
    String message = "";
    switch (code) {
      case 0x01: message = "Single Button Press"; break;
      case 0x02: message = "Double Button Press"; break;
      case 0x03: message = "Long Press Start"; break;
      case 0x04: message = "Long Press End"; break;
      case 0x10: message = "Low Battery Warning"; break;
      case 0x11: message = "Thermal Warning"; break;
      case 0x20: message = "Night Mode Activated"; break;
      case 0x21: message = "Night Mode Deactivated"; break;
      default: message = "Unknown Event: $code";
    }
    _eventController.add(message);
  }

  Future<void> writeCommand(Map<String, dynamic> command) async {
    if (commandChar != null) {
      String jsonString = jsonEncode(command);
      await commandChar!.write(utf8.encode(jsonString));
    }
  }
}