import streamlit as st
import cv2
import requests
import numpy as np
import time
import threading
import queue
import urllib.request

# --- CONFIGURATION ---
st.set_page_config(
    page_title="SightSync Qwen-VL Testing",
    page_icon="🤖",
    layout="wide"
)

# --- THREADED VIDEO CAPTURE (Manual HTTP MJPEG parsing for macOS compatibility) ---
# cv2.VideoCapture often fails on macOS with raw MJPEG streams over HTTP.
# We parse the multipart boundaries manually using urllib for maximum compatibility.

class VideoStreamThread:
    def __init__(self, src):
        self.src = src
        self.stream = None
        self.stopped = False
        self.q = queue.Queue(maxsize=1) 
    
    def start(self):
        t = threading.Thread(target=self.update, args=())
        t.daemon = True
        t.start()
        return self
    
    def update(self):
        # Universal MJPEG parser using standard library
        # Bypasses all OpenCV FFMPEG/GStreamer backend macOS bugs completely
        # by manually extracting the JPEGs and just running imdecode.
        import urllib.request
        
        while not self.stopped:
            try:
                self.stream = urllib.request.urlopen(self.src, timeout=3)
                bytes_buf = b''
                
                while not self.stopped:
                    chunk = self.stream.read(4096)
                    if not chunk:
                        break # Stream died
                    
                    bytes_buf += chunk
                    
                    # Look for start (FF D8) and end (FF D9) markers
                    a = bytes_buf.find(b'\xff\xd8')
                    b = bytes_buf.find(b'\xff\xd9')
                    
                    if a != -1 and b != -1 and b > a:
                        jpg = bytes_buf[a:b+2]
                        bytes_buf = bytes_buf[b+2:] # Keep the rest of the buffer
                        
                        if len(jpg) > 0:
                            frame = cv2.imdecode(np.frombuffer(jpg, dtype=np.uint8), cv2.IMREAD_COLOR)
                            if frame is not None and frame.size > 0:
                                with self.q.mutex:
                                    self.q.queue.clear() # Zero lag
                                self.q.put(frame)
                                
            except Exception as e:
                print(f"Stream Reconnect: {e}")
                if self.stream: 
                    self.stream.close()
                time.sleep(1)
            
    def read(self):
        if self.q.empty():
            return None
        return self.q.get()
        
    def stop(self):
        self.stopped = True
        if self.stream: self.stream.close()

# --- UI HEADER ---
st.title("🤖 SightSync Local Qwen-VL Pipeline")
st.markdown("Monitor the **Seeed Studio XIAO ESP32S3**, tune the NoIR sensor explicitly, and run 100% local inference using `qwen2.5-vl`.")

# --- SIDEBAR: SETTINGS & CONNECTION ---
st.sidebar.header("🔌 Connection Details")
esp_ip = st.sidebar.text_input("ESP32 IP Address", st.session_state.get('ip', '172.20.10.2'))
if esp_ip:
    st.session_state['ip'] = esp_ip

ollama_url = st.sidebar.text_input("Ollama API URL", "http://localhost:11434")

# URLs
stream_url = f"http://{esp_ip}:81/"
api_url = f"http://{esp_ip}/"

# Manage Video Thread in Session State so it persists across reruns
if 'video_thread' not in st.session_state:
    st.session_state.video_thread = None
if 'is_streaming' not in st.session_state:
    st.session_state.is_streaming = False

with st.sidebar:
    st.divider()
    if not st.session_state.is_streaming:
        # Note: Button still uses use_container_width in Streamlit 1.49, 
        # but st.image requires width="stretch"
        if st.button("▶️ Connect to Camera Stream", use_container_width=True, type="primary"):
            st.session_state.video_thread = VideoStreamThread(stream_url).start()
            st.session_state.is_streaming = True
            st.rerun()
    else:
        if st.button("⏹️ Disconnect Stream", use_container_width=True):
            if st.session_state.video_thread:
                st.session_state.video_thread.stop()
                st.session_state.video_thread = None
            st.session_state.is_streaming = False
            st.rerun()

# --- MAIN LAYOUT ---
col_vid, col_controls = st.columns([2, 1])

# --- VIDEO STREAM COLUMN ---
with col_vid:
    st.header("📸 OpenCV Stream Buffer")
    video_placeholder = st.empty()
    frame_metrics = st.empty()
    
    # AI Action Box
    with st.container(border=True):
        st.subheader("🧠 Qwen-VL Local Inference")
        ai_prompt = st.text_input("Prompt:", "Describe this scene accurately.")
        if st.button("⚡ Run Inference on Current Buffer", use_container_width=True, type="primary"):
            st.session_state.run_inference = True
        else:
            st.session_state.run_inference = False
            
    ai_output = st.empty()

# --- HARDWARE CONTROLS COLUMN (Crucial for NoIR) ---
with col_controls:
    st.header("🎛️ Sensor Control API")
    st.markdown("Push the sensor limits when testing NoIR without IR LEDs.")
    
    # Helper func to send REST commands
    def set_sensor(var, val):
        try:
            r = requests.get(f"{api_url}control?var={var}&val={val}", timeout=1)
            if r.status_code == 200:
                pass # Success
            else:
                st.toast(f"Failed to set {var}. Is the camera running?")
        except:
            pass

    with st.expander("💡 Exposure & Gain (Crucial for IR)", expanded=True):
        # AEC (Auto Exposure)
        aec = st.toggle("Enable Auto Exposure (AEC)", value=True)
        set_sensor("aec", 1 if aec else 0)
        
        # Manual Exposure Value (Only works if AEC is OFF)
        aec_val = st.slider("Manual Exposure Time", 0, 1200, 204, step=10, disabled=aec)
        if not aec:
            set_sensor("aec_value", aec_val)
            
        st.divider()
        
        # AGC (Auto Gain)
        agc = st.toggle("Enable Auto Gain (AGC)", value=True)
        set_sensor("agc", 1 if agc else 0)
        
        # Manual Gain (Only works if AGC is OFF)
        agc_gain = st.slider("Manual Gain Multiplier", 0, 30, 0, disabled=agc)
        if not agc:
            set_sensor("agc_gain", agc_gain)

    with st.expander("🎨 Color & Image Adjustment"):
        # AWB
        awb = st.toggle("Auto White Balance (AWB)", value=True)
        set_sensor("awb", 1 if awb else 0)
        
        bri = st.slider("Brightness", -2, 2, 0)
        sen = st.slider("Contrast", -2, 2, 0)
        set_sensor("brightness", bri)
        set_sensor("contrast", sen)
        
        eff = st.selectbox("Special Effect", options=[
            (0, "None"), (1, "Negative"), (2, "Grayscale"), 
            (3, "Red Tint"), (4, "Green Tint"), (5, "Blue Tint"), (6, "Sepia")
        ], format_func=lambda x: x[1])
        set_sensor("special_effect", eff[0])

# --- OLLAMA INFERENCE FUNCTION ---
def run_qwen_inference(frame_rgb, prompt, ollama_url):
    import base64
    from io import BytesIO
    from PIL import Image
    
    # 1. Convert Numpy RGB to Base64 JPEG
    pil_img = Image.fromarray(frame_rgb)
    buffered = BytesIO()
    pil_img.save(buffered, format="JPEG", quality=85)
    img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
    
    # 2. Call Ollama local API
    endpoint = f"{ollama_url}/api/generate"
    payload = {
        "model": "qwen3-vl:2b", 
        "prompt": prompt,
        "images": [img_str],
        "stream": False
    }
    
    try:
        r = requests.post(endpoint, json=payload, timeout=60)
        r.raise_for_status()
        return r.json().get("response", "No response block.")
    except Exception as e:
        return f"Error connecting to local Qwen-VL: {e}"

# --- MAIN STREAM READING LOOP ---
# This loop runs constantly while streaming is active to push frames to the UI
if st.session_state.is_streaming and st.session_state.video_thread:
    
    last_ui_update = time.time()
    frames_processed = 0
    start_time = time.time()
    
    # Create a place to store the most recent frame so we can inference against it
    latest_frame_rgb = None
    
    while True:
        frame = st.session_state.video_thread.read()
        
        if frame is not None:
            # OpenCV provides BGR, Streamlit needs RGB
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            latest_frame_rgb = frame_rgb
            frames_processed += 1
            
            # Update UI at most 15 times a second to prevent Streamlit from dying
            if time.time() - last_ui_update > (1.0 / 15.0):
                # The deprecation warning says to use width="stretch" or use_container_width=True
                # But due to internal streamlit bugs, use_container_width throws fake warnings
                # We will suppress it using use_container_width=True as it is the canonical way
                video_placeholder.image(frame_rgb, width="stretch")
                
                # Calculate FPS roughly
                elapsed = time.time() - start_time
                fps = frames_processed / elapsed if elapsed > 0 else 0
                frame_metrics.caption(f"Buffer Ingestion: ~{fps:.1f} FPS")
                
                last_ui_update = time.time()
                
        # Handle the one-shot inference request
        if st.session_state.run_inference and latest_frame_rgb is not None:
            st.session_state.run_inference = False # Reset flag
            
            with ai_output.container():
                st.info("🧠 Passing OpenCV buffer to robust local Qwen-VL...")
                start_inf = time.time()
                
                # Draw a flash effect to show which frame was grabbed
                flash_frame = latest_frame_rgb.copy()
                cv2.rectangle(flash_frame, (0,0), (flash_frame.shape[1], flash_frame.shape[0]), (0, 255, 0), 10)
                video_placeholder.image(flash_frame, width="stretch")
                
                # Call Ollama
                answer = run_qwen_inference(latest_frame_rgb, ai_prompt, ollama_url)
                
                inf_time = time.time() - start_inf
                st.success(f"**Qwen-VL Output** (in {inf_time:.1f}s):")
                st.write(answer)
                
            # Break loop to let streamlit rerun with the new output painted
            break
            
        time.sleep(0.01) # Tiny sleep to prevent 100% CPU lockup on wait

elif not st.session_state.is_streaming:
    video_placeholder.info("Stream disconnected. Click 'Connect to Camera Stream' in the sidebar.")
