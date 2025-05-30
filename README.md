# 🌡️ Temperature & Humidity Monitoring System with Relay & Live Graph 📊

Welcome to this real-time sensor monitoring project! Using an ESP32 microcontroller, a DHT11 sensor, and a relay, this system captures temperature and humidity every 10 seconds, stores data securely, and instantly visualizes it on a mobile/web app. Plus, it automatically triggers a relay alarm/fan when environmental thresholds are exceeded — smart, simple, and effective!

---

## 🚀 Key Features

- **Continuous Monitoring:** Measures temperature (°C) and humidity (%) every 10 seconds with precision
- **Automated Relay Control:** Relay activates when temperature > 26°C or humidity > 70% (configurable)
- **Robust Data Storage:** Sensor readings saved with timestamps in a SQL database (MySQL/PostgreSQL)
- **Real-Time Visualization:** Beautiful graphs and alerts on mobile/web app using Flutter/React Native
- **OLED Display:** Instant live feedback right on the device

---

## 🎨 Interface

![Image](https://github.com/user-attachments/assets/8b560b08-59e1-4916-86b8-2054937e3aa0)
![Image](https://github.com/user-attachments/assets/03989c4f-cea2-4f8d-a607-5227a1c21b15)
![Image](https://github.com/user-attachments/assets/f2f2cc6c-83f3-46a0-afe3-d1ec26e3c80f)

### Mobile/Web App UI Highlights

- **Live Graph Display:** Interactive line charts showing temperature and humidity trends updated every 10 seconds  
- **Current Status:** Latest sensor readings prominently displayed with color-coded alerts (e.g., red for high temperature)  
- **Relay Status Indicator:** Visual cue showing whether the relay is ON or OFF  
- **User Settings:** Allows users to configure temperature and humidity threshold values (optional feature)  
- **Clean & Responsive Design:** Easy to use with clear fonts and intuitive layout, works on various screen sizes
