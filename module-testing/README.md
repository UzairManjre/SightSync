# ESP32S3 Sense Testing Suite

This suite allows you to test the camera and hardware status of the Seeed Studio XIAO ESP32S3 Sense.

## 1. Firmware Upload
1. Open `firmware/firmware.ino` in the Arduino IDE.
2. Go to **Tools > Board** and select **XIAO_ESP32S3**.
3. **IMPORTANT**: Go to **Tools > PSRAM** and select **OPI PSRAM**.
4. Update the `ssid` and `password` variables in the code with your WiFi details.
5. Click **Upload**.
6. Open the **Serial Monitor** (115200 baud) to find the IP address once it connects.

## 2. Dashboard Setup
1. Open a terminal in the `dashboard` folder.
2. Install dependencies:
   ```bash
   pip install streamlit opencv-python requests pandas numpy
   ```
3. Run the dashboard:
   ```bash
   streamlit run app.py
   ```
4. Enter the ESP32's IP address in the sidebar.
