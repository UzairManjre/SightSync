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

  // Dual Device Support
  BluetoothDevice? leftDevice;
  BluetoothDevice? rightDevice;

  BluetoothCharacteristic? leftCommandChar;
  BluetoothCharacteristic? rightCommandChar;
  BluetoothCharacteristic? leftEventChar;
  BluetoothCharacteristic? rightEventChar;
  BluetoothCharacteristic? leftBatteryChar;
  BluetoothCharacteristic? rightBatteryChar;

  // Stream for Events (Consolidated from both arms)
  final StreamController<Map<String, dynamic>> _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  // Stream for Battery Levels
  final StreamController<Map<String, int>> _batteryController = StreamController<Map<String, int>>.broadcast();
  Stream<Map<String, int>> get batteryStream => _batteryController.stream;

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
    await _discoverServices(device, "left");
  }

  Future<void> connectRight(BluetoothDevice device) async {
    await device.connect();
    rightDevice = device;
    await _discoverServices(device, "right");
  }

  Future<void> disconnect() async {
    if (leftDevice != null) await leftDevice!.disconnect();
    if (rightDevice != null) await rightDevice!.disconnect();
    leftDevice = null;
    rightDevice = null;
    leftCommandChar = null;
    rightCommandChar = null;
    leftEventChar = null;
    rightEventChar = null;
    leftBatteryChar = null;
    rightBatteryChar = null;
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
      case 0x11: message = "Thermal Warning"; break;
      default: message = "Event: $code";
    }
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