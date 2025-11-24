import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  // UUIDs from spec
  final String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  final String commandCharUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  final String eventCharUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  final String dataStreamCharUuid = "6E400004-B5A3-F393-E0A9-E50E24DCCA9E";

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? commandChar;
  BluetoothCharacteristic? eventChar;
  BluetoothCharacteristic? dataStreamChar;

  final StreamController<String> _eventController = StreamController<String>.broadcast();
  Stream<String> get eventStream => _eventController.stream;

  Future<void> init() async {
    // Check permissions
    if (await Permission.location.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted) {
      // Permissions granted
    }
  }

  Future<void> startScan() async {
    await FlutterBluePlus.startScan(
      withServices: [Guid(serviceUuid)],
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
      dataStreamChar = null;
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase() == serviceUuid) {
        for (var characteristic in service.characteristics) {
          String uuid = characteristic.uuid.toString().toUpperCase();
          if (uuid == commandCharUuid) {
            commandChar = characteristic;
          } else if (uuid == eventCharUuid) {
            eventChar = characteristic;
            await _setupNotifications(eventChar!);
          } else if (uuid == dataStreamCharUuid) {
            dataStreamChar = characteristic;
          }
        }
      }
    }
  }

  Future<void> _setupNotifications(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    characteristic.lastValueStream.listen((value) {
      // Handle hex codes
      if (value.isNotEmpty) {
        int code = value[0];
        _handleEventCode(code);
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
    } else {
      throw Exception("Command Characteristic not found or device not connected");
    }
  }
}
