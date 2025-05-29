#include <WiFi.h>
#include <DHT.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <Adafruit_SSD1306.h>
#include <Wire.h>
#include <ArduinoJson.h>

// Hardware Configuration
#define DHT_PIN 4
#define DHT_TYPE DHT11
#define RELAY_PIN 25
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1

// WiFi Credentials
const char* ssid = "hfsha";
const char* pass = "12345678";

// Server Configuration
const char* server = "humancc.site";
const char* endpoint = "/shahidatulhidayah/iottraining/backend/dht11_api.php";
const int deviceId = 101;

// Default Sensor Thresholds (will be updated from server)
float tempThreshold = 26.0;
float humThreshold = 70.0;

// Global Objects
DHT dht(DHT_PIN, DHT_TYPE);
WiFiClientSecure client;
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Timing variables
unsigned long previousMillis = 0;
const long interval = 10000;
unsigned long lastDisplayUpdate = 0;
const long displayInterval = 2000;
int displayState = 0;

void setup() {
  Serial.begin(115200);

  // Initialize Hardware
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  dht.begin();

  // Initialize OLED
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("SSD1306 allocation failed"));
    for(;;);
  }
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0,0);
  display.println("System Starting...");
  display.display();
  delay(2000);

  // Connect to WiFi
  connectToWiFi();

  // Configure HTTPS
  client.setInsecure();

  // Initial fetch of thresholds after connecting
  fetchThresholds();

  display.setTextSize(2);
}

void loop() {
  unsigned long currentMillis = millis();

  // Handle sensor reading and data transmission
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;

    float temperature, humidity;
    if (!readSensor(&temperature, &humidity)) {
      temperature = NAN;
      humidity = NAN;
    }

    String relayStatus = controlRelay(temperature, humidity);

    if (WiFi.status() == WL_CONNECTED) {
      sendDataAndFetchThresholds(temperature, humidity, relayStatus);
    } else {
      Serial.println("WiFi disconnected. Reconnecting...");
      connectToWiFi();
    }
  }

  // Handle OLED display updates
  if (currentMillis - lastDisplayUpdate >= displayInterval) {
    lastDisplayUpdate = currentMillis;
    updateDisplay();
    displayState = (displayState + 1) % 4;
  }

  delay(10);
}

bool readSensor(float *temp, float *hum) {
  yield();
  *hum = dht.readHumidity();
  yield();
  *temp = dht.readTemperature();

  if (isnan(*hum) || isnan(*temp)) {
    Serial.println("DHT read failed!");
    return false;
  }

  Serial.printf("Temp: %.1f°C | Hum: %.1f%%\n", *temp, *hum);
  return true;
}

String controlRelay(float temp, float hum) {
  bool shouldActivate = (temp != NAN && temp > tempThreshold) || (hum != NAN && hum > humThreshold);
  digitalWrite(RELAY_PIN, shouldActivate ? HIGH : LOW);

  String status = shouldActivate ? "On" : "Off";
  static bool wasActive = false;
  if (shouldActivate && !wasActive) {
    Serial.println("Relay ACTIVATED (Threshold exceeded)");
    wasActive = true;
  } else if (!shouldActivate && wasActive) {
    Serial.println("Relay DEACTIVATED");
    wasActive = false;
  }
  return status;
}

void connectToWiFi() {
  Serial.print("Connecting to WiFi...");
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0,0);
  display.println("Connecting");
  display.println("to WiFi...");
  display.display();

  WiFi.begin(ssid, pass);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
    yield();
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("\nConnected! IP: %s\n", WiFi.localIP().toString().c_str());
    display.clearDisplay();
    display.setCursor(0,0);
    display.setTextSize(1);
    display.println("WiFi Connected!");
    display.setTextSize(1);
    display.println(WiFi.localIP().toString().c_str());
    display.display();
    delay(2000);
    display.setTextSize(2);
  } else {
    Serial.println("\nFailed to connect!");
    display.clearDisplay();
    display.setCursor(0,0);
    display.setTextSize(1);
    display.println("WiFi");
    display.println("Connection");
    display.println("Failed!");
    display.display();
  }
}

// Function to send sensor data and fetch thresholds
void sendDataAndFetchThresholds(float temp, float hum, String relayStatus) {
  HTTPClient http;

  String url = "https://" + String(server) + String(endpoint) +
               "?id=" + String(deviceId) +
               "&temp=" + String(temp) +
               "&hum=" + String(hum) +
               "&relay=" + relayStatus;

  Serial.println("Sending to: " + url);

  http.begin(client, url);
  int httpCode = http.GET();

  if (httpCode > 0) {
    Serial.printf("HTTP Response: %d\n", httpCode);
    if (httpCode == HTTP_CODE_OK) {
      String payload = http.getString();
      Serial.println("Server response: " + payload);

      StaticJsonDocument<512> doc;
      DeserializationError error = deserializeJson(doc, payload);

      if (error) {
        Serial.print(F("deserializeJson() failed: "));
        Serial.println(error.f_str());
      } else {
        if (doc["status"] == "success" && doc.containsKey("data")) {
          JsonObject data = doc["data"];
          if (data.containsKey("temp_threshold") && data.containsKey("hum_threshold")) {
            float newTempThreshold = data["temp_threshold"].as<float>();
            float newHumThreshold = data["hum_threshold"].as<float>();
            if (newTempThreshold != tempThreshold || newHumThreshold != humThreshold) {
              tempThreshold = newTempThreshold;
              humThreshold = newHumThreshold;
              Serial.printf("Thresholds updated: Temp=%.1f°C, Hum=%.1f%%\n", tempThreshold, humThreshold);
            }
          }
        }
      }
    }
  } else {
    Serial.printf("HTTP Error: %s\n", http.errorToString(httpCode).c_str());
  }

  http.end();
}

// Function to fetch thresholds specifically (on startup)
void fetchThresholds() {
  HTTPClient http;
  String url = "https://" + String(server) + String(endpoint) +
               "?id=" + String(deviceId) +
               "&fetch_thresholds=true";

  Serial.println("Fetching thresholds from: " + url);

  http.begin(client, url);
  int httpCode = http.GET();

  if (httpCode > 0) {
    Serial.printf("HTTP Response: %d\n", httpCode);
    if (httpCode == HTTP_CODE_OK) {
      String payload = http.getString();
      Serial.println("Threshold fetch response: " + payload);

      StaticJsonDocument<256> doc;
      DeserializationError error = deserializeJson(doc, payload);

      if (error) {
        Serial.print(F("deserializeJson() failed during fetch: "));
        Serial.println(error.f_str());
      } else {
        if (doc["status"] == "success" && doc["data"].containsKey("temp_threshold") && doc["data"].containsKey("hum_threshold")) {
          tempThreshold = doc["data"]["temp_threshold"].as<float>();
          humThreshold = doc["data"]["hum_threshold"].as<float>();
          Serial.printf("Initial thresholds set: Temp=%.1f°C, Hum=%.1f%%\n", tempThreshold, humThreshold);
        }
      }
    }
  } else {
    Serial.printf("HTTP Error during fetch: %s\n", http.errorToString(httpCode).c_str());
  }

  http.end();
}

void updateDisplay() {
  display.clearDisplay();
  display.setTextColor(WHITE);

  float currentTemp = dht.readTemperature();
  float currentHum = dht.readHumidity();

  switch(displayState) {
    case 0:
      display.setTextSize(2);
      display.setCursor(0,0);
      display.println("Temp");
      if (isnan(currentTemp)) {
        display.println("Failed!");
      } else {
        display.println(String(currentTemp, 1) + " C");
      }
      break;

    case 1:
      display.setTextSize(2);
      display.setCursor(0,0);
      display.println("Hum");
      if (isnan(currentHum)) {
        display.println("Failed!");
      } else {
        display.println(String(currentHum, 1) + " %");
      }
      break;

    case 2:
      display.setTextSize(2);
      display.setCursor(0,0);
      display.println("Relay");
      display.println(digitalRead(RELAY_PIN) ? "ACTIVE" : "INACTIVE");
      break;

    case 3:
      display.setTextSize(1);
      display.setCursor(0,0);
      display.println("Thresholds:");

      display.setTextSize(2);
      display.setCursor(0, 16); // Slightly below the title
      display.printf("T:%.1fC\n", tempThreshold);
      display.setCursor(0, 40);
      display.printf("H:%.1f%%", humThreshold);
      break;
  }

  display.display();
}
