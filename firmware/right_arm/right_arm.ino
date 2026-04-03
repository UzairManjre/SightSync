// ============================================================
//  SightSync — Right Arm (XIAO ESP32S3 Sense)
//  Combined: BLE + WiFi + OV2640 Camera Streaming
// ============================================================
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <WiFi.h>
#include <esp_camera.h>
#include <esp_http_server.h>

// ==========================
//  CONFIGURE YOUR WIFI HERE
// ==========================
#define WIFI_SSID     "Iphone"      // <-- Your hotspot name
#define WIFI_PASSWORD "20211310pd"    // <-- Your hotspot password

// ==========================
//  BLE Config
// ==========================
#define DEVICE_NAME       "SightSync-R1"
#define SERVICE_UUID      "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define COMMAND_CHAR_UUID "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define EVENT_CHAR_UUID   "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
#define IP_CHAR_UUID      "6E400004-B5A3-F393-E0A9-E50E24DCCA9E"
#define BATTERY_SERVICE_UUID "180F"
#define BATTERY_LEVEL_UUID   "2A19"

// ==========================
//  Camera Pin Config (XIAO ESP32S3 Sense)
// ==========================
#define PWDN_GPIO_NUM  -1
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM  10
#define SIOD_GPIO_NUM  40
#define SIOC_GPIO_NUM  39
#define Y9_GPIO_NUM    48
#define Y8_GPIO_NUM    11
#define Y7_GPIO_NUM    12
#define Y6_GPIO_NUM    14
#define Y5_GPIO_NUM    16
#define Y4_GPIO_NUM    18
#define Y3_GPIO_NUM    17
#define Y2_GPIO_NUM    15
#define VSYNC_GPIO_NUM 38
#define HREF_GPIO_NUM  47
#define PCLK_GPIO_NUM  13

// ==========================
//  State
// ==========================
BLEServer *pServer = nullptr;
BLECharacteristic *pEventChar = nullptr;
BLECharacteristic *pBatteryChar = nullptr;
BLECharacteristic *pIpChar = nullptr;
bool deviceConnected = false;
bool oldDeviceConnected = false;
uint8_t batteryLevel = 100;
long    lastUpdate   = 0;
const int BUTTON_PIN = 21; // Hardware button on XIAO
const int VBAT_PIN   = 1;  // D0/A0 - Assuming 100k/100k divider if present
bool    buttonPrev   = HIGH;
String  thermalStatus = "COOL";

httpd_handle_t camera_httpd = NULL;
bool cameraOk = false;
bool wifiOk = false;

// ==========================
//  BLE Callbacks
// ==========================
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) {
    deviceConnected = true;
    Serial.println("[BLE] Client Connected!");
  };
  void onDisconnect(BLEServer *pServer) {
    deviceConnected = false;
    Serial.println("[BLE] Client Disconnected — restarting advertising...");
  }
};

class MyCommandCallbacks : public BLECharacteristicCallbacks {
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

// ==========================
//  Camera Stream Handler
// ==========================
#define PART_BOUNDARY "123456789000000000000987654321"
static const char* _STREAM_CONTENT_TYPE = "multipart/x-mixed-replace;boundary=" PART_BOUNDARY;
static const char* _STREAM_BOUNDARY = "\r\n--" PART_BOUNDARY "\r\n";
static const char* _STREAM_PART = "Content-Type: image/jpeg\r\nContent-Length: %zu\r\n\r\n";

static esp_err_t stream_handler(httpd_req_t *req) {
  camera_fb_t *fb = NULL;
  esp_err_t res = ESP_OK;
  char part_buf[64];

  res = httpd_resp_set_type(req, _STREAM_CONTENT_TYPE);
  if (res != ESP_OK) return res;

  while (true) {
    fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println("[CAM] Frame capture failed");
      res = ESP_FAIL;
    } else {
      if (res == ESP_OK)
        res = httpd_resp_send_chunk(req, _STREAM_BOUNDARY, strlen(_STREAM_BOUNDARY));
      if (res == ESP_OK) {
        size_t hlen = snprintf(part_buf, 64, _STREAM_PART, fb->len);
        res = httpd_resp_send_chunk(req, part_buf, hlen);
      }
      if (res == ESP_OK)
        res = httpd_resp_send_chunk(req, (const char *)fb->buf, fb->len);
    }
    if (fb) esp_camera_fb_return(fb);
    if (res != ESP_OK) break;
  }
  return res;
}

// ── Single-frame JPEG capture — used by the AI service ──────────────────────
// The app calls GET /capture to grab one high-quality image without interrupting
// the live stream. This avoids the single-client limitation of the MJPEG stream.
static esp_err_t capture_handler(httpd_req_t *req) {
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    httpd_resp_send_500(req);
    return ESP_FAIL;
  }
  httpd_resp_set_type(req, "image/jpeg");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  esp_err_t res = httpd_resp_send(req, (const char *)fb->buf, fb->len);
  esp_camera_fb_return(fb);
  Serial.println("[CAM] /capture served one frame for AI analysis");
  return res;
}

static esp_err_t index_handler(httpd_req_t *req) {
  String html = "<html><body style='background:#000;color:#fff;font-family:sans-serif;text-align:center'>";
  html += "<h2>SightSync Camera</h2>";
  html += "<img src='/stream' style='max-width:100%;border-radius:12px;'>";
  html += "<br><a href='/capture' style='color:#7DF9FF'>Capture Single Frame</a>";
  html += "</body></html>";
  httpd_resp_set_type(req, "text/html");
  httpd_resp_send(req, html.c_str(), html.length());
  return ESP_OK;
}

void startCameraServer() {
  httpd_config_t config = HTTPD_DEFAULT_CONFIG();
  config.server_port = 80;

  httpd_uri_t index_uri   = { .uri = "/",        .method = HTTP_GET, .handler = index_handler,   .user_ctx = NULL };
  httpd_uri_t stream_uri  = { .uri = "/stream",   .method = HTTP_GET, .handler = stream_handler,  .user_ctx = NULL };
  httpd_uri_t capture_uri = { .uri = "/capture",  .method = HTTP_GET, .handler = capture_handler, .user_ctx = NULL };

  if (httpd_start(&camera_httpd, &config) == ESP_OK) {
    httpd_register_uri_handler(camera_httpd, &index_uri);
    httpd_register_uri_handler(camera_httpd, &stream_uri);
    httpd_register_uri_handler(camera_httpd, &capture_uri);
    Serial.println("[CAM] HTTP server started on port 80");
    Serial.println("[CAM] Stream:   http://" + WiFi.localIP().toString() + "/stream");
    Serial.println("[CAM] Capture:  http://" + WiFi.localIP().toString() + "/capture");
  } else {
    Serial.println("[CAM] Failed to start HTTP server!");
  }
}

// ==========================
//  Setup
// ==========================
void setup() {
  Serial.begin(115200);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  delay(1000);
  Serial.println("\n\n==============================================");
  Serial.println("   SightSync Right Arm — Booting...");
  Serial.println("==============================================\n");

  // Check PSRAM
  Serial.printf("[SYSTEM] PSRAM Total: %u bytes\n", ESP.getPsramSize());
  Serial.printf("[SYSTEM] PSRAM Free:  %u bytes\n", ESP.getFreePsram());
  if (ESP.getPsramSize() == 0) {
    Serial.println("[SYSTEM] ❌ PSRAM NOT DETECTED — Camera will almost certainly fail.");
  }

  // ── 1. Camera ──────────────────────────────────────────────
  Serial.println("[CAM] Initializing camera...");
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer   = LEDC_TIMER_0;
  config.pin_d0       = Y2_GPIO_NUM;
  config.pin_d1       = Y3_GPIO_NUM;
  config.pin_d2       = Y4_GPIO_NUM;
  config.pin_d3       = Y5_GPIO_NUM;
  config.pin_d4       = Y6_GPIO_NUM;
  config.pin_d5       = Y7_GPIO_NUM;
  config.pin_d6       = Y8_GPIO_NUM;
  config.pin_d7       = Y9_GPIO_NUM;
  config.pin_xclk     = XCLK_GPIO_NUM;
  config.pin_pclk     = PCLK_GPIO_NUM;
  config.pin_vsync    = VSYNC_GPIO_NUM;
  config.pin_href     = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn     = PWDN_GPIO_NUM;
  config.pin_reset    = RESET_GPIO_NUM;
  config.xclk_freq_hz = 10000000; // Reduced from 20MHz for stability
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size   = FRAMESIZE_VGA;
  config.jpeg_quality = 12;
  config.fb_count     = 1;
  config.fb_location  = CAMERA_FB_IN_PSRAM;
  config.grab_mode    = CAMERA_GRAB_WHEN_EMPTY;

  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("[CAM] ❌ Init FAILED — error 0x%x\n", err);
    if (err == 0x101) Serial.println("[CAM] Error: ESP_ERR_NO_MEM (Check if PSRAM is enabled in Tools menu!)");
    if (err == 0x105) Serial.println("[CAM] Error: ESP_ERR_NOT_FOUND (Camera sensor not detected - check ribbon cable!)");
    cameraOk = false;
  } else {
    Serial.println("[CAM] ✅ Init SUCCESS");
    sensor_t *s = esp_camera_sensor_get();
    if(s) {
      Serial.printf("[CAM] Sensor PID: 0x%02X\n", s->id.PID);
      // Flip vertical for better view
      s->set_vflip(s, 1); 
      s->set_hmirror(s, 0);
    }
    cameraOk = true;
  }

  // ── 2. WiFi ────────────────────────────────────────────────
  Serial.printf("\n[WIFI] Connecting to: %s\n", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int wifiAttempts = 0;
  while (WiFi.status() != WL_CONNECTED && wifiAttempts < 20) {
    delay(500);
    Serial.print(".");
    wifiAttempts++;
  }
  Serial.println();
  if (WiFi.status() == WL_CONNECTED) {
    wifiOk = true;
    Serial.println("[WIFI] ✅ Connected!");
    Serial.print("[WIFI] IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.print("[WIFI] Signal (RSSI): ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
    if (cameraOk) startCameraServer();
  } else {
    wifiOk = false;
    Serial.println("[WIFI] ❌ Connection FAILED — check SSID/password");
  }

  // ── 3. BLE ─────────────────────────────────────────────────
  Serial.println("\n[BLE] Initializing...");
  BLEDevice::init(DEVICE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  BLECharacteristic *pCommandChar = pService->createCharacteristic(COMMAND_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  pCommandChar->setCallbacks(new MyCommandCallbacks());
  pEventChar = pService->createCharacteristic(EVENT_CHAR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  pEventChar->addDescriptor(new BLE2902());
  
  pIpChar = pService->createCharacteristic(
              IP_CHAR_UUID, 
              BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
            );
  pIpChar->addDescriptor(new BLE2902());
  
  if (wifiOk) {
    String ipStr = WiFi.localIP().toString();
    pIpChar->setValue(ipStr.c_str());
  } else {
    pIpChar->setValue("0.0.0.0");
  }

  BLEService *pBatteryService = pServer->createService(BATTERY_SERVICE_UUID);
  pBatteryChar = pBatteryService->createCharacteristic(BATTERY_LEVEL_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pBatteryChar->addDescriptor(new BLE2902());
  pBatteryChar->setValue(&batteryLevel, 1);

  pService->start();
  pBatteryService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  BLEAdvertisementData oScanResponseData;
  oScanResponseData.setName(DEVICE_NAME);
  pAdvertising->setScanResponseData(oScanResponseData);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  // Print advertised name from constants
  Serial.println("[BLE] ✅ Advertising started!");
  Serial.print("[BLE] Name: ");
  Serial.println(DEVICE_NAME);
  Serial.print("[BLE] MAC Address: ");
  Serial.println(BLEDevice::getAddress().toString().c_str());

  // ── Summary ────────────────────────────────────────────────
  Serial.println("\n==============================================");
  Serial.println("   SightSync Right Arm — Ready");
  Serial.printf("   Camera:  %s\n", cameraOk ? "✅ OK" : "❌ FAILED");
  Serial.printf("   WiFi:    %s\n", wifiOk ? ("✅ " + WiFi.localIP().toString()).c_str() : "❌ Not Connected");
  Serial.println("   BLE:     ✅ " + String(DEVICE_NAME));
  Serial.println("   Battery: Simulated (To use real LiPo monitoring, wire A0 with 100k/100k divider)");
  Serial.println("==============================================\n");
}

// ==========================
//  Loop
// ==========================
void loop() {
  // 1. Handle Connectivity
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("[BLE] Restarting advertising...");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
    Serial.println("[BLE] Linked to SightSync App (Master/Right)");
    
    // Proactively push IP on reconnection
    if (wifiOk && pIpChar) {
      String ipStr = WiFi.localIP().toString();
      pIpChar->setValue(ipStr.c_str());
      pIpChar->notify();
    }
  }

  // 2. Telemetry Updates (Every 3 seconds)
  if (deviceConnected && (millis() - lastUpdate > 3000)) {
    lastUpdate = millis();
    
    // --- BATTERY TELEMETRY (STABLE SOURCE) ---
    // Since the device is on a stable power source (USB/Fixed), we keep it at 100%.
    // In a final battery-powered build, uncomment the AnalogRead sensing logic.
    batteryLevel = 100;
    
    pBatteryChar->setValue(&batteryLevel, 1);
    pBatteryChar->notify();

    // Thermal Simulation (Affected by camera state)
    uint8_t thermalCode = (camera_httpd != NULL) ? 0x00 : 0x00; // Even with camera, keep it COOL unless actual heat
    // In actual use, we'd send 0x11 if (temp > 45)
    pEventChar->setValue(&thermalCode, 1);
    pEventChar->notify();

    Serial.printf("[TELEMETRY] Batt: %d%% | Signal (WiFi): %d dBm | CAM: %s\n", 
                  batteryLevel, wifiOk ? WiFi.RSSI() : 0, cameraOk ? "ON" : "OFF");
  }

  // 3. Physical Button Monitoring (GPIO 21)
  bool buttonNow = digitalRead(BUTTON_PIN);
  if (buttonNow == LOW && buttonPrev == HIGH) {
    Serial.println("[EVENT] Button Pressed (Right) -> Sending Event 0x01");
    uint8_t eventCode = 0x01; // Trigger Action
    pEventChar->setValue(&eventCode, 1);
    pEventChar->notify();
    delay(200); // Debounce
  }
  buttonPrev = buttonNow;

  delay(10);
}
