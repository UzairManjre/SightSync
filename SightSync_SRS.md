# Software Requirements Specification (SRS)
## Project: SightSync
**Author:** Pal Gandhi  
**Date:** March 2026  
**Document Version:** 2.0 (Enterprise Standard)  

---

## Table of Contents
1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [System Features (Functional Requirements)](#3-system-features-functional-requirements)
4. [External Interface Requirements](#4-external-interface-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)

---

## 1. Introduction

### 1.1 Purpose
The purpose of this Software Requirements Specification (SRS) is to detail the comprehensive software and firmware requirements for **SightSync**, an AI-powered assistive wearable device for the visually impaired. It describes the scope, operating environment, and functional behaviors of the entire stack, functioning as the central contract between hardware, edge computing, and cloud application integration.

### 1.2 Document Conventions
Items labeled **FR-XX** designate Functional Requirements, and **NFR-XX** designate Non-Functional Requirements. Use Case diagrams are provided using standard UML/Mermaid syntax. Priority levels are defined as [Critical], [High], [Medium], and [Low].

### 1.3 Intended Audience
This document is intended for software engineers, ML engineers, embedded systems programmers, PCB hardware designers, and project stakeholders.

### 1.4 Product Scope
SightSync eliminates the boundaries of visual disability by leveraging a 2-tier architectural system consisting of a wearable edge edge device (Dual-ESP32S3) functioning synchronously with a mobile hub (Flutter App). The system utilizes multi-modal AI spanning from 150ms on-device collision avoidance to deep cloud-based Scene Description via Generative AI APIs. It distinctively implements active 850nm/940nm Night Vision optics to function efficiently in 0-lux environments.

---

## 2. Overall Description

### 2.1 Product Perspective
SightSync relies on two primary nodes:
1.  **Node 1 (The Wearable):** Composed of Left and Right frames utilizing Seeed XIAO ESP32S3 Sense microcontrollers. Handles immediate sensory logging (ToF proximity), visual streaming (MJPEG HTTP), and audio playback (I2S Transducers).
2.  **Node 2 (The Smartphone Hub):** An iOS/Android device running the SightSync application. Interprets incoming data, executes quantized edge ML models locally, and serves as an internet gateway for massive parameter cloud models.

### 2.2 System Use Case Diagram

```mermaid
usecaseDiagram
    actor "Visually Impaired User" as User
    actor "Sighted Guardian" as Guardian

    package SightSync_Edge {
        usecase "Avoid Obstacles" as UC1
        usecase "Capture Audio Wake Word" as UC2
        usecase "Toggle Night Vision (IR)" as UC3
    }
    
    package SightSync_Mobile Hub {
        usecase "Read Text (OCR)" as UC4
        usecase "Recognize Face" as UC5
        usecase "Recognize Currency" as UC6
        usecase "Stream Video Feed" as UC7
    }

    package SightSync_Cloud Services {
        usecase "Describe Scene (LLM)" as UC8
        usecase "Send Emergency SOS" as UC9
        usecase "Video Calling" as UC10
    }

    User --> UC1
    User --> UC2
    User --> UC3
    User --> UC4
    User --> UC5
    User --> UC6
    User --> UC8
    User --> UC9
    User --> UC10

    UC10 <-- Guardian
    UC9 <-- Guardian
    UC7 --> UC10
```

### 2.3 User Classes and Characteristics
*   **Primary User (Visually Impaired):** Relies solely on rich auditory spatial cues. Requires purely hands-free operability or easily identifiable physical tactile buttons.
*   **Secondary User (Sighted Guardian/Volunteer):** Operates normal mobile GUI interfaces to accept VideoCalls or view dynamic maps from triggered SOS texts.

### 2.4 Operating Environment
*   **Firmware:** RTOS/C++ embedded environment, constrained to ESP32S3 PSRAM sizing and thermal throttling limits.
*   **Mobile Software:** Flutter matching standard iOS (SDK >= 14) and Android (API >= 24) dependencies.
*   **Database:** Local SQLite datastores and remote Google Firebase.

---

## 3. System Features (Functional Requirements)

This section maps directly to the locked 9-feature capability set.

### 3.1 FR-01: Auto/Manual Night Vision Switching [Critical]
*   **Description:** The hardware features standard OV5640 sensors alongside OV3360/OV2640 NoIR sensors and 8x IR LEDs. The software must regulate switching.
*   **Inputs:** Ambient light drop (derived via CV or photoresistor), or manual voice command ("Turn on Night Vision").
*   **Outputs:** GPIO toggle on the IR LED MOSFET array.
*   **Dependencies:** None. This is an edge-based hardware toggle.

### 3.2 FR-02: Chatbot Wake Word (Hey SightSync) [High]
*   **Description:** A continuous listening daemon monitoring the I2S MEMS microphone for a predefined acoustic model.
*   **Inputs:** Ambient room audio.
*   **Outputs:** Trigger/Interrupt firing to the mobile application via BLE GATT Notify.
*   **Quality Requirement:** Wake word False Positive Rate (FPR) strictly < 5%.

### 3.3 FR-03: Emergency SOS Protocol [Critical]
*   **Description:** An instant priority-override action triggering an SMS broadcast and Firebase Push Notification.
*   **Inputs:** 3-second physical button hold OR vocal command ("SightSync, SOS").
*   **Outputs:** The App acquires GPS coordinates, extracts 1 MJPEG frame, and transmits a payload stating: `"Emergency! Pal needs help at [Lat, Lng]. Video frame attached."`

### 3.4 FR-04: Deep Generative Scene Description [Medium]
*   **Description:** Offloads an image matrix to a Vision LLM for contextual semantic parsing.
*   **Inputs:** Extracted JPEG frame + "Describe the scene" string.
*   **Outputs:** Synthesized TTS Audio output (e.g., "A crowded subway station with a train approaching on the left").
*   **Preconditions:** Stable Wi-Fi bridge to the mobile device and an active cellular/broadband connection.

### 3.5 FR-05: Edge Object Detection - Collision Avoidance [Critical]
*   **Description:** Utilizing 3x VL53L1X ToF distance matrices, calculated securely on the ESP32S3.
*   **Inputs:** Distance arrays polled at 10Hz.
*   **Outputs:** Scaled PWM audio frequency on the bone-conduction transducers. The pitch scales inversely to distance (higher pitch = closer obstacle).

### 3.6 FR-06: Mobile Edge Text Reading (OCR) [High]
*   **Description:** The user points their head at a document. The app performs local MLKit/CoreML optical character recognition.
*   **Inputs:** 10-second video buffer from the `right_arm.ino` HTTP stream.
*   **Outputs:** Extracted text strings queued into the device TTS synthesizer.

### 3.7 FR-07: Mobile Edge Currency Recognition [Medium]
*   **Description:** Fast edge quantized object detection (`.tflite`) targeting major global fiat currencies.
*   **Inputs:** Incoming real-time video stream.
*   **Outputs:** Audio affirmation (e.g., "Twenty Dollars detected").

### 3.8 FR-08: WebRTC VideoCalling & Remote Assistance [Medium]
*   **Description:** Connecting the local wearable camera feed securely to a remote mobile client.
*   **Inputs:** Real-time HTTP MJPEG stream payload.
*   **Outputs:** Bi-directional WebRTC VoIP channel providing the remote Guardian with a 30 FPS video feed and a full-duplex audio stream.

### 3.9 FR-09: Mobile Edge Face Recognition [Low/Medium]
*   **Description:** Maintaining a local database of familial tensor embeddings, updating the system state when friends approach.
*   **Inputs:** Continuous video monitoring against a SQLite `Faces` embeddings table.
*   **Outputs:** "Pal is approaching from the front."

---

## 4. External Interface Requirements

### 4.1 User Interfaces
The primary UI is entirely auditory/haptic for the primary user. Secondary UI (Setup/Dashboard/Guide) is built in Flutter adhering to WCAG 2.1 AA contrast constraints, utilizing large scalable typography for low-vision individuals.

### 4.2 Hardware Interfaces
The system communicates heavily across standard embedded bus protocols:
- `I2C` (SDA/SCL) for TCA9548A Multiplexer and ToF Sensors.
- `I2S` (BCLK/LRC/DIN) for INMP441 Microphone array.

### 4.3 Communications Interfaces
- **BLE (Bluetooth Low Energy) 5.0:** Service UUID `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` handles discrete `<100 byte` logic transfer (Commands/Heartbeats).
- **TCP/IPv4 via Wi-Fi STA/SoftAP:** A localized Class C subnet handling contiguous `multipart/x-mixed-replace` video payloads.

---

## 5. Non-Functional Requirements

### 5.1 Performance Requirements
*   **NFR-01:** System boot to functional collision avoidance < 5.0 seconds.
*   **NFR-02:** Local Mobile AI tasks (OCR, Currency, Faces) TTFB (Time To First Byte of Audio) < 1000ms.
*   **NFR-03:** Cloud-based Generative AI tasks TTFB < 3000ms.

### 5.2 Security Requirements
*   **NFR-04:** No facial tensor embeddings or physical location mappings may be uploaded to cloud databases under any circumstances (GDPR/CCPA privacy adherence).
*   **NFR-05:** MQTT or Firebase channels must operate strictly over port 443 (TLS v1.3).

### 5.3 Hardware Constraints & Reliability
*   **NFR-06:** Given maximum active heat threshold guidelines for wearable skin-contact tech, the dual-core ESP32S3 modules must throttle processing to maintain an external chassis temperature < 42°C (107°F).
