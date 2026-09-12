# Gayen Family Farm — Solar Soil Moisture + SMS Alert System
# Spec: ESP32 + GSM + Capacitive Sensors + Solar
# Budget: Under $200 USD
# Target: 31 ha cashew farm, The Gambia, West Africa
# Well: 11m depth, 5m water column, solar submersible pump

---

## 1. System Overview

```
[Solar Panel 6W] -> [Charge Controller] -> [18650 Battery]
                                              |
                              [ESP32 + SIM800L GSM Module]
                                    |              |
                          [Soil Sensor x3]    [SMS to Modou]
                                              [SMS to Pump Relay (future)]
```

**What it does:**
- Reads soil moisture at 3 points across the farm every 30 minutes
- Sends SMS alert when soil is too dry (pump needed) or saturated (stop pump)
- Sends daily summary SMS at 6 AM with all readings
- Logs data to onboard flash (SD card) for grant reporting
- Runs entirely on solar — no grid power needed

---

## 2. Bill of Materials

| # | Component | Qty | Unit $ | Total $ | Source |
|---|-----------|-----|--------|---------|--------|
| 1 | ESP32-WROOM-32 dev board | 1 | $4.50 | $4.50 | AliExpress |
| 2 | SIM800L GSM module (with antenna) | 1 | $6.00 | $6.00 | AliExpress |
| 3 | Capacitive soil moisture sensor v1.2 | 3 | $1.50 | $4.50 | AliExpress |
| 4 | 6W 6V solar panel | 1 | $12.00 | $12.00 | AliExpress |
| 5 | TP4056 charge controller (with protection) | 1 | $0.80 | $0.80 | AliExpress |
| 6 | 18650 Li-ion battery 3400mAh | 2 | $3.50 | $7.00 | AliExpress |
| 7 | 18650 battery holder (2-cell series) | 1 | $1.00 | $1.00 | AliExpress |
| 8 | LM2596 buck converter (adjustable) | 2 | $1.50 | $3.00 | AliExpress |
| 9 | Micro SD card module + 8GB card | 1 | $3.00 | $3.00 | AliExpress |
| 10 | IP65 waterproof junction box (150x110x70mm) | 1 | $5.00 | $5.00 | AliExpress |
| 11 | Cable glands PG7 (for sensor wires) | 4 | $0.30 | $1.20 | AliExpress |
| 12 | 3-core cable 0.5mm2 (20m for sensor runs) | 1 | $8.00 | $8.00 | Local/AliExpress |
| 13 | Dupont jumper wires (40-pin M-F) | 1 | $1.50 | $1.50 | AliExpress |
| 14 | SIM card (Africell or QCell Gambia, prepaid) | 1 | $2.00 | $2.00 | Local |
| 15 | SMS credit (6 months) | 1 | $10.00 | $10.00 | Local |
| 16 | PVC pipe 1 inch (1m, for sensor stake housing) | 3 | $1.00 | $3.00 | Local |
| 17 | 1000uF electrolytic capacitor (for SIM800L) | 1 | $0.50 | $0.50 | AliExpress |
| 18 | Zip ties, heat shrink, solder, misc | 1 | $5.00 | $5.00 | Local |
| 19 | Shipping to Gambia (AliExpress consolidated) | 1 | $25.00 | $25.00 | AliExpress |
| | | | **TOTAL** | **$103.00** | |

**Budget margin: $97 remaining** for contingency, replacement parts, or a second sensor node.

---

## 3. Wiring Diagram

```
SOLAR PANEL (6V 6W)
  (+) --> TP4056 IN+
  (-) --> TP4056 IN-

TP4056 (Charge Controller)
  BAT+ --> 18650 Battery Pack (+)
  BAT- --> 18650 Battery Pack (-)
  OUT+ --> LM2596 #1 IN+  AND  LM2596 #2 IN+
  OUT- --> LM2596 #1 IN-  AND  LM2596 #2 IN-

LM2596 #1 (set to 3.3V -- for ESP32 + sensors + SD)
  OUT+ --> ESP32 3V3 pin
  OUT- --> ESP32 GND

LM2596 #2 (set to 4.0V -- for SIM800L)
  OUT+ --> SIM800L VCC  (with 1000uF cap across VCC/GND)
  OUT- --> SIM800L GND

ESP32 Connections:
  GPIO 34 (ADC) <-- Soil Sensor 1 (AOUT)
  GPIO 35 (ADC) <-- Soil Sensor 2 (AOUT)
  GPIO 32 (ADC) <-- Soil Sensor 3 (AOUT)
  GPIO 17 (TX2)  --> SIM800L RX
  GPIO 16 (RX2)  <-- SIM800L TX
  GPIO 5  (CS)   --> SD Card Module CS
  GPIO 23 (MOSI) --> SD Card Module MOSI
  GPIO 19 (MISO) <-- SD Card Module MISO
  GPIO 18 (SCK)  --> SD Card Module SCK
  3V3            --> Soil Sensors VCC (all 3)
  3V3            --> SD Card Module VCC
  GND            --> All GND (common ground bus)

CRITICAL: SIM800L draws 2A peaks during transmit.
          The 1000uF cap across VCC/GND is mandatory.
          Separate LM2596 at 4.0V prevents ESP32 brownout.
```

---

## 4. Firmware

```cpp
// gayen_farm_monitor.ino
// ESP32 Soil Moisture + SMS Alert System
// For: Modou Gaye, Gayen Family Farm, The Gambia
// By: Helix AI Innovations (pro bono)

#include <HardwareSerial.h>
#include <SD.h>
#include <SPI.h>

// === PIN DEFINITIONS ===
#define SOIL_1 34
#define SOIL_2 35
#define SOIL_3 32
#define SIM_TX 17
#define SIM_RX 16
#define SD_CS  5

// === CONFIGURATION ===
// CHANGE THIS to Modou's actual number
const char* PHONE_MODOU = "+220XXXXXXX";

const unsigned long READ_INTERVAL_US = 1800000000ULL; // 30 min in microseconds
const int DAILY_REPORT_HOUR = 6;    // 6 AM local
const int DRY_THRESHOLD = 40;       // Below 40% = too dry, start pump
const int WET_THRESHOLD = 85;       // Above 85% = saturated, stop pump

// === CALIBRATION (adjust after field install) ===
// Capacitive sensor: air ~3200 (dry), water ~1400 (wet)
int AIR_VALUE = 3200;
int WATER_VALUE = 1400;

// === GLOBALS ===
HardwareSerial sim800(2);
bool sdReady = false;
int bootCount = 0;
RTC_DATA_ATTR int persistBootCount = 0;
RTC_DATA_ATTR float dailyMin[3] = {100, 100, 100};
RTC_DATA_ATTR float dailyMax[3] = {0, 0, 0};
RTC_DATA_ATTR float dailySum[3] = {0, 0, 0};
RTC_DATA_ATTR int dailyCount = 0;
RTC_DATA_ATTR int lastAlertHour = -1;
RTC_DATA_ATTR bool startupSent = false;

void setup() {
    Serial.begin(115200);
    persistBootCount++;
    bootCount = persistBootCount;

    // Init ADC
    analogReadResolution(12);
    analogSetAttenuation(ADC_11db);

    // Init SIM800L
    sim800.begin(9600, SERIAL_8N1, SIM_RX, SIM_TX);
    delay(3000);
    sendAT("AT");
    sendAT("AT+CMGF=1");
    sendAT("AT+CSCS=\"GSM\"");

    // Init SD
    if (SD.begin(SD_CS)) {
        sdReady = true;
    }

    // First boot startup message
    if (!startupSent) {
        sendSMS(PHONE_MODOU,
            "Gayen Farm Monitor ONLINE\n"
            "Sensors: 3 active\n"
            "Alerts: Dry<40% Wet>85%\n"
            "Daily report at 6AM\n"
            "- Steve & Helix AI");
        startupSent = true;
    }

    // === MAIN WORK ===
    float moisture[3];
    moisture[0] = readMoisture(SOIL_1);
    moisture[1] = readMoisture(SOIL_2);
    moisture[2] = readMoisture(SOIL_3);

    Serial.printf("Boot %d: S1=%.0f%% S2=%.0f%% S3=%.0f%%\n",
        bootCount, moisture[0], moisture[1], moisture[2]);

    // Update daily stats (persists across deep sleep)
    for (int i = 0; i < 3; i++) {
        if (moisture[i] < dailyMin[i]) dailyMin[i] = moisture[i];
        if (moisture[i] > dailyMax[i]) dailyMax[i] = moisture[i];
        dailySum[i] += moisture[i];
    }
    dailyCount++;

    // Log to SD
    logToSD(moisture);

    // Check alerts (rate limited: 1 per hour)
    checkAlerts(moisture);

    // Check daily report (6 AM)
    checkDailyReport(moisture);

    // Deep sleep until next reading
    Serial.println("Sleeping 30 min...");
    esp_sleep_enable_timer_wakeup(READ_INTERVAL_US);
    esp_deep_sleep_start();
}

void loop() {
    // Never reached -- deep sleep restarts from setup()
}

float readMoisture(int pin) {
    long sum = 0;
    for (int i = 0; i < 10; i++) {
        sum += analogRead(pin);
        delay(10);
    }
    int raw = sum / 10;
    float pct = (float)(AIR_VALUE - raw) / (AIR_VALUE - WATER_VALUE) * 100.0;
    if (pct < 0) pct = 0;
    if (pct > 100) pct = 100;
    return pct;
}

void checkAlerts(float moisture[3]) {
    // Simple hour tracking via boot count (48 boots per day at 30 min)
    int approxHour = (bootCount * 30 / 60) % 24;
    if (approxHour == lastAlertHour) return;

    for (int i = 0; i < 3; i++) {
        if (moisture[i] < DRY_THRESHOLD) {
            char msg[160];
            snprintf(msg, sizeof(msg),
                "DRY ALERT Sensor %d: %.0f%%\n"
                "S1:%.0f%% S2:%.0f%% S3:%.0f%%\n"
                "-> Start pump",
                i+1, moisture[i],
                moisture[0], moisture[1], moisture[2]);
            sendSMS(PHONE_MODOU, msg);
            lastAlertHour = approxHour;
            return;
        }
        if (moisture[i] > WET_THRESHOLD) {
            char msg[160];
            snprintf(msg, sizeof(msg),
                "WET ALERT Sensor %d: %.0f%%\n"
                "S1:%.0f%% S2:%.0f%% S3:%.0f%%\n"
                "-> Stop pump",
                i+1, moisture[i],
                moisture[0], moisture[1], moisture[2]);
            sendSMS(PHONE_MODOU, msg);
            lastAlertHour = approxHour;
            return;
        }
    }
}

void checkDailyReport(float moisture[3]) {
    int approxHour = (bootCount * 30 / 60) % 24;
    if (approxHour != DAILY_REPORT_HOUR || dailyCount == 0) return;

    // Only send once per day (check if we already sent this cycle)
    static RTC_DATA_ATTR int lastReportDay = -1;
    int approxDay = bootCount / 48;
    if (approxDay == lastReportDay) return;
    lastReportDay = approxDay;

    char msg[160];
    snprintf(msg, sizeof(msg),
        "DAILY REPORT\n"
        "S1: %.0f%% (%.0f-%.0f)\n"
        "S2: %.0f%% (%.0f-%.0f)\n"
        "S3: %.0f%% (%.0f-%.0f)\n"
        "Reads: %d",
        dailySum[0]/dailyCount, dailyMin[0], dailyMax[0],
        dailySum[1]/dailyCount, dailyMin[1], dailyMax[1],
        dailySum[2]/dailyCount, dailyMin[2], dailyMax[2],
        dailyCount);
    sendSMS(PHONE_MODOU, msg);

    // Reset daily stats
    for (int i = 0; i < 3; i++) {
        dailyMin[i] = 100;
        dailyMax[i] = 0;
        dailySum[i] = 0;
    }
    dailyCount = 0;
}

void logToSD(float moisture[3]) {
    if (!sdReady) return;
    File f = SD.open("/farm.csv", FILE_APPEND);
    if (f) {
        f.printf("%d,%.1f,%.1f,%.1f\n",
            bootCount, moisture[0], moisture[1], moisture[2]);
        f.close();
    }
}

void sendSMS(const char* number, const char* message) {
    char cmd[32];
    snprintf(cmd, sizeof(cmd), "AT+CMGS=\"%s\"", number);
    sendAT(cmd);
    delay(100);
    sim800.print(message);
    sim800.write(0x1A);
    delay(5000);
    while (sim800.available()) sim800.read();
}

void sendAT(const char* cmd) {
    sim800.println(cmd);
    delay(500);
    while (sim800.available()) Serial.write(sim800.read());
}
```

---

## 5. Sensor Placement

```
Farm Layout (31 ha):

    [WELL + BOX]  <-- ESP32 + solar panel mounted here
         |
         | 5m cable
         |
        [S1]  (near well, reference/calibration)
         .
         .  ~200m cable in buried PVC
         .
        [S2]  (mid-field)
         .
         .  ~400m cable (or second node)
         .
        [S3]  (far end, worst-case dryness)
```

**Cable note:** Capacitive sensors lose accuracy beyond ~50m. Options:
- **Phase 1:** S1 on short cable (5m). Test S2 at distance. If signal degrades, deploy S2/S3 as independent nodes (+$30 each).
- **Phase 2:** ESP-NOW peer-to-peer WiFi between nodes (200m line-of-sight, no SIM needed for relay nodes).

---

## 6. Assembly Checklist

1. Set LM2596 #1 to 3.3V and #2 to 4.0V BEFORE connecting anything. Use multimeter.
2. Solder 1000uF cap across SIM800L VCC/GND. It will not transmit without it.
3. Mount in IP65 box. Solar panel on top lid. Cable glands on bottom.
4. Sensor stakes: cut 1 inch PVC to 30cm, drill holes for water contact, insert sensor, seal top with silicone.
5. Bury cables 10cm deep in conduit.
6. Insert SIM card with SMS credit loaded.
7. Power on. Wait for startup SMS. No SMS in 5 min = check antenna.

---

## 7. Calibration (after install)

1. Hold sensor in air 30 seconds. Note ADC value. Set as AIR_VALUE in firmware.
2. Submerge sensor in cup of water. Note ADC value. Set as WATER_VALUE.
3. After 1 week: adjust DRY_THRESHOLD and WET_THRESHOLD based on what Modou sees in the field.

---

## 8. Data for Grant Applications

SD card logs CSV: `boot_count, sensor1_pct, sensor2_pct, sensor3_pct`

Use for:
- Before/after charts for Kiva profile
- Evidence of need for Water Mission / Grundfos applications
- Farm Radio International programming data
- Any NGO that wants to see real numbers

---

## 9. Phase 2 Upgrades (if funded)

| Upgrade | Cost | Benefit |
|---------|------|---------|
| Pump relay (auto on/off via SMS command) | $15 | Automated irrigation |
| Rain gauge (tipping bucket) | $8 | Skip irrigation after rain |
| DHT22 temp/humidity sensor | $3 | Crop stress monitoring |
| Second sensor node (far field) | $30 | Full 31 ha coverage |
| GPRS data upload | $5/mo | Remote dashboard |

---

**Phase 1 total: ~$103 | Budget remaining: $97**

Farms build nations. 🦉⚓🦆
