#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// SightSync UUIDs
#define SERVICE_UUID        "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define COMMAND_CHAR_UUID   "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define EVENT_CHAR_UUID     "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

// Battery Service UUID
#define BATTERY_SERVICE_UUID "180F"
#define BATTERY_LEVEL_UUID   "2A19"

BLEServer* pServer = nullptr;
BLECharacteristic* pEventChar = nullptr;
BLECharacteristic* pBatteryChar = nullptr;
bool deviceConnected = false;
bool oldDeviceConnected = false;
uint8_t batteryLevel = 85;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

class MyCommandCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String value = pCharacteristic->getValue().c_str();
      if (value.length() > 0) {
        Serial.print("Received Command on Left Arm: ");
        Serial.println(value.c_str());
      }
    }
};

void setup() {
  Serial.begin(115200);

  // Initialize BLE for LEFT Arm
  BLEDevice::init("SightSync-L");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // 1. SightSync Custom Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Command Characteristic (Write)
  BLECharacteristic *pCommandChar = pService->createCharacteristic(
                                         COMMAND_CHAR_UUID,
                                         BLECharacteristic::PROPERTY_WRITE
                                       );
  pCommandChar->setCallbacks(new MyCommandCallbacks());

  // Event Characteristic (Notify)
  pEventChar = pService->createCharacteristic(
                      EVENT_CHAR_UUID,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pEventChar->addDescriptor(new BLE2902());

  // 2. Battery Service
  BLEService *pBatteryService = pServer->createService(BATTERY_SERVICE_UUID);
  pBatteryChar = pBatteryService->createCharacteristic(
                                         BATTERY_LEVEL_UUID,
                                         BLECharacteristic::PROPERTY_READ   |
                                         BLECharacteristic::PROPERTY_NOTIFY
                                       );
  pBatteryChar->addDescriptor(new BLE2902());
  pBatteryChar->setValue(&batteryLevel, 1);

  // Start Services
  pService->start();
  pBatteryService->start();

  // 3. Start Advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->addServiceUUID(BATTERY_SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06); // functions that help with iPhone connection issues
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("LEFT ARM BLE Advertising Started - Waiting for connections...");
}

void loop() {
    // Handle disconnecting
    if (!deviceConnected && oldDeviceConnected) {
        delay(500); // give the bluetooth stack the chance to get things ready
        pServer->startAdvertising(); // restart advertising
        Serial.println("Restarting advertising...");
        oldDeviceConnected = deviceConnected;
    }
    // Handle connecting
    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
        Serial.println("Device Connected to Left Arm!");
    }
    delay(100);
}
