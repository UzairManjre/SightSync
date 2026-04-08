#include "esp_camera.h"
#include "esp_http_server.h"
#include <WiFi.h>

/**
 * SightSync XIAO ESP32S3 Sense - Final Testing Firmware (Qwen / NoIR)
 * -------------------------------------------------------------------
 * INSTRUCTIONS:
 * 1. Set Tools > Board > Seeed XIAO ESP32S3
 * 2. Set Tools > PSRAM > OPI PSRAM
 * 3. Set Tools > Flash Size > 8MB
 * 4. Enable iPhone Hotspot 'Maximize Compatibility'
 */

// WiFi Configuration
const char *ssid = "Iphone";
const char *password = "20211310pd";

// XIAO ESP32S3 Camera Pins
#define PWDN_GPIO_NUM -1
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM 10
#define SIOD_GPIO_NUM 40
#define SIOC_GPIO_NUM 39

#define Y9_GPIO_NUM 48
#define Y8_GPIO_NUM 11
#define Y7_GPIO_NUM 12
#define Y6_GPIO_NUM 14
#define Y5_GPIO_NUM 16
#define Y4_GPIO_NUM 18
#define Y3_GPIO_NUM 17
#define Y2_GPIO_NUM 15
#define VSYNC_GPIO_NUM 38
#define HREF_GPIO_NUM 47
#define PCLK_GPIO_NUM 13

httpd_handle_t StreamServer = NULL;
httpd_handle_t APIServer = NULL;

// Forward Declarations
void startCameraServer();

void setup() {
  Serial.begin(115200);
  delay(3000);

  Serial.println("\n\n--- XIAO ESP32S3 Sense Setup (SightSync Qwen Pipeline) ---");

  // 1. PSRAM Check
  Serial.print("Checking PSRAM... ");
  if (psramFound()) {
    Serial.printf("Detected! Size: %d KB\n", ESP.getPsramSize() / 1024);
  } else {
    Serial.println("NOT FOUND! Go to Tools > PSRAM > OPI PSRAM.");
    while (1) {
      delay(1000);
    }
  }

  // 2. Camera Configuration
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  
  // High res for AI processing
  config.frame_size = FRAMESIZE_XGA;  // Use XGA (1024x768) for much better clarity
  config.pixel_format = PIXFORMAT_JPEG;
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 8; // Lower number means higher quality
  config.fb_count = 2; // Dual buffer for streaming

  Serial.print("Initialising Camera... ");
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("FAILED (0x%x)\n", err);
    return;
  }
  Serial.println("SUCCESS!");
  
  // Set default settings suitable for both normal and NoIR
  sensor_t * s = esp_camera_sensor_get();
  // Turn off white balance and exposure auto-adjustment by default for NoIR testing
  // The python UI will override these immediately anyway.
  s->set_vflip(s, 0); // Flip if needed based on hardware mounting
  s->set_hmirror(s, 0);

  // 3. WiFi Connection
  Serial.printf("Connecting to Hotspot: %s\n", ssid);
  WiFi.begin(ssid, password);

  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 30) {
    delay(1000);
    Serial.print(".");
    retry++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf(
        "\nCONNECTED:\n  Stream: http://%s:81/\n  API:    http://%s/\n",
        WiFi.localIP().toString().c_str(), WiFi.localIP().toString().c_str());
  } else {
    Serial.println("\nWiFi FAILED.");
  }

  // 4. Start Server
  startCameraServer();
  Serial.println("Dual-Server Started.");
}

void loop() { delay(10000); }


// --- MJPEG STREAM HANDLER (For Python OpenCV ingestion) ---
#define PART_BOUNDARY "123456789000000000000987654321"
static const char* _STREAM_CONTENT_TYPE = "multipart/x-mixed-replace;boundary=" PART_BOUNDARY;
static const char* _STREAM_BOUNDARY = "\r\n--" PART_BOUNDARY "\r\n";
static const char* _STREAM_PART = "Content-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n";

static esp_err_t stream_handler(httpd_req_t *req) {
  camera_fb_t *fb = NULL;
  esp_err_t res = ESP_OK;
  char part_buf[64];
  
  httpd_resp_set_type(req, _STREAM_CONTENT_TYPE);
  
  while (true) {
    fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println("Camera capture failed");
      res = ESP_FAIL;
    } else {
      size_t hlen = snprintf(part_buf, 64, _STREAM_PART, fb->len);
      res = httpd_resp_send_chunk(req, part_buf, hlen);
      if (res == ESP_OK) {
        res = httpd_resp_send_chunk(req, (const char *)fb->buf, fb->len);
      }
      if (res == ESP_OK) {
        res = httpd_resp_send_chunk(req, _STREAM_BOUNDARY, strlen(_STREAM_BOUNDARY));
      }
      esp_camera_fb_return(fb);
    }
    if (res != ESP_OK) {
      break;
    }
  }
  return res;
}

// --- SINGLE CAPTURE HANDLER ---
static esp_err_t capture_handler(httpd_req_t *req) {
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    httpd_resp_send_500(req);
    return ESP_FAIL;
  }
  httpd_resp_set_type(req, "image/jpeg");
  httpd_resp_set_hdr(req, "Content-Disposition", "inline; filename=capture.jpg");
  esp_err_t res = httpd_resp_send(req, (const char *)fb->buf, fb->len);
  esp_camera_fb_return(fb);
  return res;
}

// --- HARDWARE STATUS HANDLER ---
static esp_err_t status_handler(httpd_req_t *req) {
  char json[256];
  sensor_t * s = esp_camera_sensor_get();
  sprintf(json, 
    "{\"rssi\":%d,\"heap\":%u,\"psram\":%u,"
    "\"exposure_ctrl\":%d,\"aec_value\":%d,"
    "\"gain_ctrl\":%d,\"agc_gain\":%d,"
    "\"awb\":%d,\"wb_mode\":%d,"
    "\"brightness\":%d,\"contrast\":%d,"
    "\"special_effect\":%d}", 
    WiFi.RSSI(), ESP.getFreeHeap(), ESP.getPsramSize(),
    s->status.aec, s->status.aec_value,
    s->status.agc, s->status.agc_gain,
    s->status.awb, s->status.wb_mode,
    s->status.brightness, s->status.contrast,
    s->status.special_effect
  );
  httpd_resp_set_type(req, "application/json");
  return httpd_resp_send(req, json, strlen(json));
}

// --- CAMERA SENSOR CONTROL ENGINE (For NoIR / General Tuning) ---
// Takes URL params like: /control?var=brightness&val=1
static esp_err_t control_handler(httpd_req_t *req) {
  char buf[32];
  size_t buf_len;
  char variable[32];
  char value[32];

  buf_len = httpd_req_get_url_query_len(req) + 1;
  if (buf_len > 1 && buf_len < sizeof(buf)) {
    if (httpd_req_get_url_query_str(req, buf, buf_len) == ESP_OK) {
      if (httpd_query_key_value(buf, "var", variable, sizeof(variable)) == ESP_OK &&
          httpd_query_key_value(buf, "val", value, sizeof(value)) == ESP_OK) {
            
            int val = atoi(value);
            sensor_t * s = esp_camera_sensor_get();
            int res = 0;
            
            // Map the variable string to actual sensor controls
            if (!strcmp(variable, "brightness")) res = s->set_brightness(s, val); // -2 to 2
            else if (!strcmp(variable, "contrast")) res = s->set_contrast(s, val); // -2 to 2
            else if (!strcmp(variable, "saturation")) res = s->set_saturation(s, val); // -2 to 2
            else if (!strcmp(variable, "special_effect")) res = s->set_special_effect(s, val); // 0 to 6
            // Auto Exposure / Manual Exposure
            else if (!strcmp(variable, "aec")) res = s->set_exposure_ctrl(s, val); // 0 = disable, 1 = enable
            else if (!strcmp(variable, "aec_value")) res = s->set_aec_value(s, val); // 0 to 1200
            // Auto Gain / Manual Gain
            else if (!strcmp(variable, "agc")) res = s->set_gain_ctrl(s, val); // 0 = disable, 1 = enable
            else if (!strcmp(variable, "agc_gain")) res = s->set_agc_gain(s, val); // 0 to 30
            // Auto White Balance / Manual WB
            else if (!strcmp(variable, "awb")) res = s->set_whitebal(s, val); // 0 = disable, 1 = enable
            else if (!strcmp(variable, "wb_mode")) res = s->set_wb_mode(s, val); // 0 to 4
            // Image Flip
            else if (!strcmp(variable, "vflip")) res = s->set_vflip(s, val); // 0 or 1
            else if (!strcmp(variable, "hmirror")) res = s->set_hmirror(s, val); // 0 or 1
            else {
              res = -1;
            }

            if (res) {
              return httpd_resp_send_500(req);
            }
            
            httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
            return httpd_resp_send(req, NULL, 0); // OK
      }
    }
  }
  return httpd_resp_send_404(req);
}

void startCameraServer() {
  httpd_config_t config_stream = HTTPD_DEFAULT_CONFIG();
  config_stream.server_port = 81;
  config_stream.ctrl_port = 32768; // Unique
  
  httpd_config_t config_api = HTTPD_DEFAULT_CONFIG();
  config_api.server_port = 80;
  config_api.ctrl_port = 32769; // Unique

  httpd_uri_t stream_uri = { .uri = "/", .method = HTTP_GET, .handler = stream_handler };
  httpd_uri_t capture_uri = { .uri = "/capture", .method = HTTP_GET, .handler = capture_handler };
  httpd_uri_t status_uri = { .uri = "/status", .method = HTTP_GET, .handler = status_handler };
  httpd_uri_t control_uri = { .uri = "/control", .method = HTTP_GET, .handler = control_handler };

  // Setup CORS globally if needed, done manually per handler here for simplicity

  if (httpd_start(&StreamServer, &config_stream) == ESP_OK) {
    httpd_register_uri_handler(StreamServer, &stream_uri);
  }

  if (httpd_start(&APIServer, &config_api) == ESP_OK) {
    httpd_register_uri_handler(APIServer, &capture_uri);
    httpd_register_uri_handler(APIServer, &status_uri);
    httpd_register_uri_handler(APIServer, &control_uri); // NEW Control Endpoint
  }
}