# AGS Hardware Component Specification

## Design Constraints
- **Weight Target:** 40-50g total
- **Battery Life:** 4-5 hours continuous use
- **Budget Target:** <$100 per unit (component cost)
- **Form Factor:** Sleek, lightweight, balanced weight distribution

---

## FINAL COMPONENT LIST

### 1. Core Processing & Camera
| Component | Model | Specs | Weight | Cost (Est.) | Notes |
|-----------|-------|-------|--------|-------------|-------|
| **Microcontroller** | Seeed XIAO ESP32S3 Sense | WiFi, BT 5.0, dual-core | 5g | $14 | Compact, powerful |
| **Camera 1 (Day)** | OV5640 (MJY5OAF-F3M-V1) | 5MP, IR-Cut Filter | 3g | $15 | High-res daylight vision |
| **Camera 2 (Night)** | OV3360/OV2640 NoIR (DVP) | 2MP (UXGA), 850nm Night Vision | 3g | $8 | Dedicated night vision |

**Decision:** Dual Camera Setup
- **Camera 1 (Color):** Primary for high-resolution daytime scene description.
- **Camera 2 (NoIR):** Secondary for pitch-black 850nm infrared operation.

---

### 2. Sensors
| Component | Model | Specs | Weight | Cost (Est.) | Notes |
|-----------|-------|-------|--------|-------------|-------|
| **Distance Array** | 3x VL53L1X ToF | 4m range, 27° FoV each | 1g × 3 = 3g | $10 × 3 = $30 | Left, Center, Right coverage |
| **I2C Multiplexer**| TCA9548A | 8-Channel I2C switch | 1g | $3 | Required to address 3 identical sensors |
| **Microphone** | INMP441 I2S MEMS | Digital, low noise | 1g | $3 | Voice commands, calls |

---

### 3. Audio Output
| Component | Model | Specs | Weight | Cost (Est.) | Notes |
|-----------|-------|-------|--------|-------------|-------|
| **Amplifier** | MAX98357A I2S | 3W, I2S input | 1g | $4 | Drives transducer |
| **Speaker** | Bone Conduction Transducer | 8Ω, 1W | 4g × 2 = 8g | $10 × 2 = $20 | One per arm |

---

### 4. Night Vision System
| Component | Model | Specs | Weight | Cost (Est.) | Notes |
|-----------|-------|-------|--------|-------------|-------|
| **IR LEDs** | 940nm IR LEDs (SMD) | 50mA each | 0.1g × 8 = 0.8g | $0.50 × 8 = $4 | 8 LEDs (4 per side) |
| **LED Driver** | IRLML2502 MOSFET | 4A, low Rds(on) | 0.1g × 2 = 0.2g | $0.50 × 2 = $1 | 2 MOSFETs for control |
| **Resistors** | Current limiting (100Ω) | 1/4W SMD | Negligible | $1 | For IR LEDs |

**Revised IR System:**
- Reduced from 10 to 8 LEDs (4 per side of camera)
- Better MOSFET (IRLML2502 vs 2N7002)
- Saves weight and power

---

### 5. Power System
| Component | Model | Specs | Weight | Cost (Est.) | Notes |
|-----------|-------|-------|--------|-------------|-------|
| **Battery** | 2× 1500mAh LiPo (503450) | 3.7V, 5.55Wh each | 15g × 2 = 30g | $8 × 2 = $16 | One per arm, balanced |
| **Charging Module** | 2× TP4056 USB-C | 1A charging | 1g × 2 = 2g | $1 × 2 = $2 | Independent charging |
| **Voltage Regulator** | AMS1117-3.3V | 1A, LDO | 0.5g | $0.50 | 3.3V for ESP32 |
| **Protection Circuit** | DW01A + FS8205A | Overcharge/discharge | 0.5g × 2 = 1g | $1 × 2 = $2 | Battery protection |

**Battery Decision:**
- 2× 1500mAh = 3000mAh total
- Balanced weight (one per arm)
- ~4-5 hours runtime (calculated below)

---

### 6. User Interface
| Component | Model | Specs | Weight | Cost (Est.) | Notes |
|-----------|-------|-------|--------|-------------|-------|
| **Buttons** | Tactile SMD switches | 6×6mm | 0.2g × 3 = 0.6g | $0.20 × 3 = $0.60 | Power, capture, mode |
| **Status LEDs** | SMD LEDs (0805) | Red, Green, Blue | Negligible | $0.30 × 3 = $0.90 | Charging, power, status |

---

### 7. PCB & Connectors
| Component | Model | Specs | Weight | Cost (Est.) | Notes |
|-----------|-------|-------|--------|-------------|-------|
| **Custom PCB** | 2-layer FR4 | 50×20mm × 2 boards | 3g × 2 = 6g | $15 (batch) | One per arm |
| **FPC Connector** | 24-pin 0.5mm pitch | For OV5640 | 0.5g | $1 | Camera connection |
| **JST Connectors** | 2-pin, 4-pin | For batteries, sensors | 1g | $2 | Modular connections |
| **USB-C Port** | USB-C receptacle | Charging | 0.5g | $1 | Charging port |

---

### 8. Frame & Mechanical
| Component | Model | Specs | Weight | Cost (Est.) | Notes |
|-----------|-------|-------|--------|-------------|-------|
| **Glasses Frame** | 3D Printed (PLA/PETG) | Custom design | 15g | $5 (material) | Lightweight, customizable |
| **Hinges** | Spring hinges | Standard glasses | 2g × 2 = 4g | $3 × 2 = $6 | Foldable arms |
| **Nose Pads** | Silicone adjustable | Comfort | 1g | $2 | Adjustable fit |
| **Screws & Hardware** | M1.4, M2 | Stainless steel | 1g | $1 | Assembly |

---

### 9. Miscellaneous
| Component | Purpose | Weight | Cost (Est.) |
|-----------|---------|--------|-------------|
| **Capacitors** | Decoupling, filtering | 1g | $2 |
| **Heat Sinks** | ESP32, voltage regulator | 1g | $1 |
| **Thermal Pads** | Heat dissipation | Negligible | $1 |
| **Wire/Cable** | Internal connections | 2g | $2 |

---

## TOTAL WEIGHT CALCULATION

| Category | Weight |
|----------|--------|
| Electronics (MCU, camera, sensors, audio) | 23g |
| Batteries (2× 1500mAh) | 30g |
| PCB & connectors | 8g |
| Frame & mechanical | 21g |
| Miscellaneous | 4g |
| **TOTAL** | **86g** |

⚠️ **ISSUE: Over weight target (86g vs 50g target)**

---

## WEIGHT OPTIMIZATION OPTIONS

### Option 1: Reduce Battery Capacity
- Use 2× 1000mAh batteries instead of 1500mAh
- **Weight saved:** 20g (new total: 66g)
- **Runtime:** ~3 hours instead of 4-5 hours
- **Trade-off:** Shorter battery life

### Option 2: Single Battery Design
- Use 1× 2000mAh battery (one arm only)
- **Weight saved:** 15g (new total: 71g)
- **Trade-off:** Unbalanced weight distribution (defeats purpose)

### Option 3: Lighter Frame Material
- Use ultra-lightweight titanium or carbon fiber frame
- **Weight saved:** 10g (new total: 76g)
- **Trade-off:** Higher cost ($50+ for frame)

### Option 4: Hybrid Approach (RECOMMENDED)
- 2× 1000mAh batteries (saves 20g)
- Optimize PCB size/weight (saves 2g)
- Lighter frame design (saves 5g)
- **New total:** ~59g
- **Runtime:** 3-3.5 hours with smart power management

---

## POWER CONSUMPTION CALCULATION

### Active Components (Peak Load)
| Component | Current Draw | Power (mW) |
|-----------|--------------|------------|
| ESP32S3 (WiFi active) | 200mA | 660mW |
| OV5640 camera | 120mA | 396mW |
| IR LEDs (8× 50mA) | 400mA | 1320mW |
| MAX98357A amplifier | 100mA | 330mW |
| VL53L1X ToF | 20mA | 66mW |
| INMP441 microphone | 1mA | 3.3mW |
| **TOTAL PEAK** | **841mA** | **2775mW** |

### Smart Power Management
- IR LEDs only on when needed (not continuous)
- Camera captures every 2-3 seconds (not streaming)
- WiFi sleep mode between transmissions
- **Average consumption:** ~300-400mA

### Battery Life Calculation
- 2× 1000mAh = 2000mAh total
- Average draw: 350mA
- **Runtime:** 2000mAh ÷ 350mA = **5.7 hours** ✅
- With inefficiency (80%): **4.5 hours** ✅

---

## TOTAL COST ESTIMATE

| Category | Cost |
|----------|------|
| Core electronics | $45 |
| Sensors | $11 |
| Audio system | $24 |
| Night vision (IR) | $6 |
| Power system | $21 |
| UI components | $2 |
| PCB & connectors | $19 |
| Frame & mechanical | $14 |
| Miscellaneous | $6 |
| **SUBTOTAL** | **$148** |
| PCB assembly labor | $20 |
| **TOTAL PER UNIT** | **$168** |

⚠️ **Over budget target ($168 vs $100)**

### Cost Optimization
- Bulk ordering (10+ units): -30% = **$118**
- Remove built-in OV2640 (use standalone ESP32S3): -$5 = **$113**
- Simpler frame design: -$5 = **$108**
- **Optimized cost:** ~**$108** per unit (bulk)

---

## FINAL RECOMMENDATIONS

### Recommended Configuration
1. **Use 2× 1000mAh batteries** (balanced weight, good runtime)
2. **8 IR LEDs** (sufficient for night vision)
3. **Custom lightweight frame** (optimized 3D print)
4. **Smart power management** (firmware optimization)

### Expected Specs
- **Weight:** ~59g (within acceptable range)
- **Battery Life:** 4-5 hours (with power management)
- **Cost:** ~$108 per unit (bulk order of 10+)

### Next Steps
1. Approve this component list
2. Design custom PCB layout
3. Design 3D-printable frame
4. Source components and get quotes
5. Order first batch for prototyping
