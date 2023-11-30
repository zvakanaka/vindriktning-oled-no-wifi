#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <U8g2lib.h>

#include "SerialCom.h"
#include "Types.h"

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0);

particleSensorState_t state;

#define statusCheckInterval 3000
uint32_t statusCheckPreviousMillis = millis();

#define DHTPIN 14     // Digital pin connected to the DHT sensor
#define DHTTYPE DHT22 // DHT 22 (AM2302)
DHT dht(DHTPIN, DHTTYPE);

// Yes, this is hacky but it is working in time to make it a Christmas gift
char identifier[24];
char avgPM25[24];
char fahrenheit[24];
char humidity[24];
#define FIRMWARE_PREFIX "esp8266-vindriktning-particle-sensor-oled"

void setup() {
  Serial.begin(115200);
  SerialCom::setup();
  dht.begin();

  Serial.println("\n");
  Serial.println("Hello from esp8266-vindriktning-particle-sensor");
  Serial.printf("Core Version: %s\n", ESP.getCoreVersion().c_str());
  Serial.printf("Boot Version: %u\n", ESP.getBootVersion());
  Serial.printf("Boot Mode: %u\n", ESP.getBootMode());
  Serial.printf("CPU Frequency: %u MHz\n", ESP.getCpuFreqMHz());
  Serial.printf("Reset reason: %s\n", ESP.getResetReason().c_str());

  u8g2.begin();
  u8g2.setContrast(0);
  u8g2.setFont(u8g2_font_unifont_t_symbols);
  u8g2.drawGlyph((128 - 12) / 2, 40, 0x23f3);

  u8g2.setFont(u8g2_font_simple1_te);
  // u8g2.clearBuffer();
  // u8g2.drawStr(0,20,"Hello from esp8266-vindriktning-particle-sensor");
  u8g2.sendBuffer();

  delay(3000);

  snprintf(identifier, sizeof(identifier), "VINDRIKTNING-%X", ESP.getChipId());
  u8g2_uint_t w = u8g2.getStrWidth(identifier);

  u8g2.clearBuffer();
  u8g2.drawStr((128 - w) / 2, (64 - 8) / 2, identifier);
  u8g2.sendBuffer();
  u8g2.setFont(u8g2_font_fub49_tn);
  Serial.printf("%s/%s/status\n", FIRMWARE_PREFIX, identifier);

  Serial.println("-- Current GPIO Configuration --");
  Serial.printf("PIN_UART_RX: %d\n", SerialCom::PIN_UART_RX);
}

void loop() {
  SerialCom::handleUart(state);

  const uint32_t currentMillis = millis();
  if (currentMillis - statusCheckPreviousMillis >= statusCheckInterval) {
    statusCheckPreviousMillis = currentMillis;

    // read temperature and humidity
    float t = dht.readTemperature();
    float h = dht.readHumidity();
    u8g2.clearBuffer();
    bool tempHumError =
        isnan(h) || isnan(t) || h > 100 || h < 0 || t > 100 || t < -40;

    u8g2.setFont(u8g2_font_simple1_te);

    if (tempHumError) {
      u8g2.setFont(u8g2_font_squeezed_r6_tr);
      u8g2.drawStr(0, 64, "Temp/humidity sensor error!");
    } else {
      snprintf(fahrenheit, sizeof(fahrenheit), "%d F", int((t * 9 / 5) + 32));
      snprintf(humidity, sizeof(humidity), "H: %d", int(h));
      u8g2.drawStr(128 - u8g2.getStrWidth(fahrenheit) - 8, 8, fahrenheit);
      u8g2.drawStr(0, 8, humidity);

      /* u8g2.setFont(u8g2_font_percent_circle_25_hn); */
      /* u8g2.drawGlyph(0, 40, 49); */
    }

    if (state.valid) {
      u8g2.setFont(u8g2_font_fub49_tn);
      snprintf(avgPM25, sizeof(avgPM25), "%d", state.avgPM25);
      u8g2_uint_t w = u8g2.getStrWidth(avgPM25);
      u8g2.drawStr((128 - w) / 2, (64 - 50) / 2 + 50, avgPM25);
    } else {
      u8g2.setFont(u8g2_font_squeezed_r6_tr);
      u8g2.drawStr(0, 20, "Particle sensor error!");
    }
    u8g2.sendBuffer();
  }
}
