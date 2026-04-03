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

// ── Telemetry State ──────────────────
uint8_t  batteryLevel = 100;
long     lastUpdate   = 0;
const int BUTTON_PIN  = 0; // Standard BOOT/USER button
const int VBAT_PIN    = 1; // D0/A0 placeholder
bool     buttonPrev   = HIGH;
String   thermalStatus = "COOL";

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
        Serial.println("--------------------------------");
        Serial.print("Received Command: ");
        Serial.println(value.c_str());
        
        // Simple search for the PIN if it's a pairing command
        if (value.indexOf("pairing_pin") != -1) {
          int pinIdx = value.indexOf("\"pin\":\"") + 7;
          if (pinIdx > 7) {
            String pin = value.substring(pinIdx, pinIdx + 6);
            Serial.println(">>> SIGHTSYNC PAIRING PIN: " + pin + " <<<");
          }
        }
        Serial.println("--------------------------------");
      }
    }
};

void setup() {
  Serial.begin(115200);
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  // Initialize BLE for LEFT Arm
  BLEDevice::init("SightSync-L1");
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
  Serial.println("[SYSTEM] Battery: Simulated (Wire A0 with divider for real readings)");
}

void loop() {
    if (!deviceConnected && oldDeviceConnected) {
        delay(500);
        pServer->startAdvertising();
        Serial.println("[BLE] Restarting advertising...");
        oldDeviceConnected = deviceConnected;
    }
    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
        Serial.println("[BLE] Linked to SightSync App (Left)");
    }

    // 2. Telemetry Updates (Every 3 seconds)
    if (deviceConnected && (millis() - lastUpdate > 3000)) {
        lastUpdate = millis();
        
        // --- BATTERY TELEMETRY (STABLE SOURCE) ---
        // Since the device is on a stable power source, we keep it at 100%.
        // In a future battery-powered build, uncomment the sensing logic.
        batteryLevel = 100; 
        
        pBatteryChar->setValue(&batteryLevel, 1);
        pBatteryChar->notify();

        // Push Thermal Status
        uint8_t thermalCode = 0x00; // Normal
        pEventChar->setValue(&thermalCode, 1);
        pEventChar->notify();
        
        Serial.printf("[TELEMETRY] Batt: %d%% | Status: %s\n", batteryLevel, thermalStatus.c_str());
    }

    // 3. Physical Button Monitoring (GPIO 0)
    bool buttonNow = digitalRead(BUTTON_PIN);
    if (buttonNow == LOW && buttonPrev == HIGH) {
        Serial.println("[EVENT] Button Pressed (Left) -> Notifying App");
        uint8_t eventCode = 0x01; // Single Press
        pEventChar->setValue(&eventCode, 1);
        pEventChar->notify();
        delay(200); // Debounce
    }
    buttonPrev = buttonNow;

    delay(10);
}
