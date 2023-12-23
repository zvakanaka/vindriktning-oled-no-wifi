#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <U8g2lib.h>
#include <CircularBuffer.h>

#include "SerialCom.h"
#include "Types.h"

U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0);

particleSensorState_t state;

#define statusCheckInterval 3000
#define BOOT_DELAY 3000
#define PARTICLE_SENSOR_LOADING_DELAY 20000

uint32_t statusCheckPreviousMillis = millis();

CircularBuffer<char,126> circBuf; // uses 538 bytes

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

  delay(BOOT_DELAY);

  snprintf(identifier, sizeof(identifier), "VINDRIKTNING-%X", ESP.getChipId());
  u8g2_uint_t w = u8g2.getStrWidth(identifier);

  /* u8g2.clearBuffer(); */
  /* u8g2.drawStr((128 - w) / 2, (64 - 8) / 2, identifier); */
  /* u8g2.sendBuffer(); */
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

    if (tempHumError) {
      // https://github.com/olikraus/u8g2/wiki/fntgrpx11#6x12
      u8g2.setFont(u8g2_font_6x12_tf);

      u8g2.drawStr(0, 64, "Temp/humidity sensor error!");
    } else {
      u8g2.setFont(u8g2_font_9x15_tf);
      snprintf(fahrenheit, sizeof(fahrenheit), "%d F", int((t * 9 / 5) + 32));

      snprintf(humidity, sizeof(humidity), "%d%%", int(h));
      u8g2.drawStr(128 - u8g2.getStrWidth(fahrenheit) - 8, 8 + 3, fahrenheit);
      // degree https://github.com/olikraus/u8g2/wiki/u8g2reference#drawcircle
      u8g2.drawCircle(128 - u8g2.getStrWidth(fahrenheit) * .333 - 8 - 1 , 2, 1, U8G2_DRAW_ALL);
      u8g2.drawStr(0, 8 + 3, humidity);
    }

    /* u8g2.drawPixel(0,0); */
    /* u8g2.drawPixel(124, 63); */
    /* u8g2.drawPixel(0,63); */
    /* u8g2.drawPixel(127,0); */

    if (state.valid) {
      u8g2.setFont(u8g2_font_fub49_tn);
      snprintf(avgPM25, sizeof(avgPM25), "%d", state.avgPM25);
      u8g2_uint_t w = u8g2.getStrWidth(avgPM25);
      bool isMoreThan2Digits = true;//state.avgPM25 > 99;
      int digitHeight = isMoreThan2Digits ? 62: 50;
      u8g2.drawStr((128 - w) / 2, (64 - digitHeight) / 2 + digitHeight, avgPM25);
      /* u8g2.drawStr((128 - w) / 2, (64 - 50) / 2 + 50, avgPM25); */

      circBuf.push(state.avgPM25);
    } else if (currentMillis < PARTICLE_SENSOR_LOADING_DELAY) {
      /* circBuf.push(currentMillis / 1000 % 126); */
      u8g2.setFont(u8g2_font_6x12_tr);
      u8g2.drawStr(0, 38, "Air sensor loading");
    } else {
      u8g2.setFont(u8g2_font_6x12_tr);
      u8g2.drawStr(0, 38, "Air sensor error");
    }

    for (decltype(circBuf)::index_t i = 0; i < circBuf.size(); i++) {
      /* u8g2.drawPixel(126 - i, 64 - circBuf[i]); */
      if (i != 0)
        u8g2.drawLine(i,     63 - circBuf[i],
                      i - 1, 63 - circBuf[i - 1]);
    }

    u8g2.sendBuffer();
  }
}
