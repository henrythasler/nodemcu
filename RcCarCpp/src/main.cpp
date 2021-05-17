/*
IR LED:
BPW40 520...950nm
Cathode GND, Anode RX
short-circuit current is 5 mA. Even at 5V it's max 25mW. BPW40 can handle up to 150mW / 100mA
*/
#include <Arduino.h>

#if defined(ARDUINO_ARCH_ESP8266) //ESP8266
#include <ESP8266WiFi.h>
// #include <ESP8266HTTPClient.h>
#include <ESP8266mDNS.h>
// #include <ESP8266WebServer.h>     // Include the WebServer library
#elif defined(ARDUINO_ARCH_ESP32) //ESP32
#include <SPIFFS.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ESPmDNS.h>
#include <WebServer.h> // Include the WebServer library
#endif

#include "config.h" // must be included as very first!
#include "wifi_config.h" // must be included as very first!

#include <LEDS.h>
#include <PubSubClient.h>
#include <transmitter.h>
#include <HardwareSerial.h>
#include "GY521.h"
#include <madgwickFilter.h>

GY521 sensor(0x68); // 0x68 => AD0 connected to ground, 0x69 => AD0 connected to VCC
uint32_t counter = 0;

LEDs leds;

WiFiClient espClient;
PubSubClient mqtt_client(espClient);

Readings reading;

Transmitter transmitter = Transmitter(&mqtt_client, &reading, &leds);

const int format_buffer_size = 128;
char format_buffer[format_buffer_size];
unsigned long millis_last_imu_read = 0;


void wifiSetup()
{
    delay(50);

    unsigned long t_start = millis();
    if (use_wifi) {
        Serial.print("Start WiFi to SSID: ");
        Serial.println(wifi_ssid);

        WiFi.mode(WIFI_STA);
        WiFi.softAPdisconnect(false);
        WiFi.enableAP(false);
        
        // WiFi.setHostname(dns_name); // ESP32
        WiFi.hostname(dns_name); // ESP8266

        int wifi_reconnect_num = 0;
        WiFi.begin(wifi_ssid, wifi_password);
        while (WiFi.status() != WL_CONNECTED)
        {
            if ((millis() - t_start) > (unsigned long) conf_wifi_reset_after_ms){
                if (conf_restart_wifi_issue){
                  Serial.print("Wifi reconnect failed! Restart ESP!");
                  ESP.restart();
                } else {
                  Serial.print("Wifi reconnect failed! Resume ...");
                  break;
                }
            }
            wifi_reconnect_num++;
            const int delay_after = 500; // milliseconds
            Serial.print(".");
            delay(delay_after);
        }
        // we are connected now!
        if (WiFi.status() == WL_CONNECTED){
            Serial.println(" ");
            Serial.printf("WiFi connected after %lu ms\n", (millis() - t_start));
            Serial.print("Connect with IP: ");
            Serial.println(WiFi.localIP());

            mqtt_client.setServer(mqtt_broker_url, mqtt_broker_port);
        }       
    }
}

// Serial2 Example: https://circuits4you.com/2018/12/31/esp32-hardware-serial2-example/

//   SETUP running once at the beginning
void setup()
{
    reading.count = 0;

    leds.setup();
    pinMode(LED_BUILTIN, OUTPUT); // Initialize the LED_BUILTIN pin as an output
    leds.led_int.blinkBlocking(2, 250, 100);  // Signal startup

    Serial.begin(115200);
    Wire.begin();
    delay(100);
    Serial.println("ESP8266-RcCar init");
    while (sensor.wakeup() == false)
    {
      Serial.print(millis());
      Serial.println("\tCould not connect to GY521");
      delay(1000);
    }
    sensor.setAccelSensitivity(2);  // 8g | 0,1,2,3 ==> 2g 4g 8g 16g
    sensor.setGyroSensitivity(1);   // 500 degrees/s | 250, 500, 1000, 2000 degrees/second

    sensor.setThrottle();
    Serial.println("start...");
        // set callibration values from calibration sketch.
    sensor.axe = 0;
    sensor.aye = 0;
    sensor.aze = 0;
    sensor.gxe = 0;
    sensor.gye = 0;
    sensor.gze = 0;

    if (use_wifi)
    {
        wifiSetup();

        if (MDNS.begin(dns_name))
        { // Start the mDNS responder for esp8266.local
            Serial.println("mDNS responder started");
        }
        else
        {
            Serial.println("Error setting up MDNS responder!");
        }

        Serial.println("HTTP server started");
    }

    leds.led_int.blinkBlocking(2, 100, 100);

    Serial.print("Transmitter Max Packet Size: ");
    Serial.println(MQTT_MAX_PACKET_SIZE);
    Serial.println("INIT Done");
}

unsigned long last_print_millis = millis();
unsigned long loop_count = 0;



void loop()
{
    loop_count++;
    unsigned long millis_now = millis();
    if ((millis_now - last_print_millis) > 500){
        Serial.print("LOOP: "); // Send some startup data to the console
        Serial.println(loop_count);
        last_print_millis = millis_now;
    }

    if (use_wifi){

        if (WiFi.status() != WL_CONNECTED)
        {
            Serial.println("\nWifi not connected any more ...");
            wifiSetup(); // this blocks and retries until connected, restarts if timout !!!
    
            delay(100);
        }

        if (WiFi.status() == WL_CONNECTED){
            if (!mqtt_client.connected())
            {
               transmitter.reconnect_mqtt(); // this blocks and retries until connected, restarts if timout !!!
            }
        }

        // All connected again
        mqtt_client.loop();
    }

  sensor.read();
  unsigned long m_read = millis();
  float pitch = sensor.getPitch();
  float roll  = sensor.getRoll();
  float yaw   = sensor.getYaw(); // 0 center, -90 > 90° right, 90 => 90° left
  float temp  = sensor.getTemperature();
  float acc_x = sensor.getAccelX(); // Rotation: 1: backward 90°, -1: forward 90%
  float acc_y = sensor.getAccelY(); // Rotation: 1: right 90°, -1: left 90%
  float acc_z = sensor.getAccelZ();
  float ang_x = sensor.getAngleX(); // Rotation: -90 till 90
  float ang_y = sensor.getAngleY(); //
  float ang_z = sensor.getAngleZ(); //
  float gyro_x = sensor.getGyroX();
  float gyro_y = sensor.getGyroY();
  float gyro_z = sensor.getGyroZ();
   /*
    imu_yaw:   (almost) stable angle of the sensor when viewed from atop (direction)
    imu_roll:  (almost) stable angle of the sensor when viewed from back (amount wingtip up/down)
    imu_pitch: (almost) stable angle of the sensor when viewed from side (amount nose up/down)
    */
   // printf("i: %d, roll: %f, pitch: %f, yaw: %f\n", loop_count, imu_roll, imu_pitch, imu_yaw);

  boolean reset = reading.count == 0; // was transmitted
  if (reset) {
    reading.count = 1;
    reading.m_first = m_read;
    reading.m_last  = m_read;
    reading.pitch   = pitch;
    reading.roll    = roll;
    reading.yaw     = yaw;
    reading.acc_x   = acc_x;
    reading.acc_y   = acc_y;
    reading.acc_z   = acc_z;
    reading.ang_x   = ang_x;
    reading.ang_y   = ang_y;
    reading.ang_z   = ang_z;
    reading.gyro_x  = gyro_x;
    reading.gyro_y  = gyro_y;
    reading.gyro_z  = gyro_z;
    reading.temp    = temp;
  } else {
    reading.count ++;
    reading.m_last = m_read;
    reading.pitch   += pitch;
    reading.roll    += roll;
    reading.yaw     += yaw;
  
    reading.acc_x   += acc_x;
    reading.acc_y   += acc_y;
    reading.acc_z   += acc_z;
    reading.ang_x   += ang_x;
    reading.ang_y   += ang_y;
    reading.ang_z   += ang_z;
    reading.gyro_x  += gyro_x;
    reading.gyro_y  += gyro_y;
    reading.gyro_z  += gyro_z;
    reading.temp    += temp;
  }

  boolean reset_imu = reading.count_imu == 0; // was transmitted

  float imu_interval_ms = 1000 / conf_imu_sample_freq_hz;
  int diff_ms = m_read - millis_last_imu_read;
  boolean read_imu = diff_ms > imu_interval_ms;
  if (read_imu && conf_imu_sample_interval_ms != conf_transmit_all_interval_ms) {
    millis_last_imu_read = m_read;
    float imu_roll = 0.0, imu_pitch = 0.0, imu_yaw = 0.0;
    if (loop_count == 1) {
        diff_ms = imu_interval_ms;
    }
    imu_filter(acc_x, acc_y, acc_z, gyro_x, gyro_y, gyro_z, diff_ms);
    eulerAngles(q_est, &imu_roll, &imu_pitch, &imu_yaw);
    if (reset_imu) {
        reading.count_imu   = 1;
        reading.imu_pitch   = imu_pitch;
        reading.imu_roll    = imu_roll;
        reading.imu_yaw     = imu_yaw;
    } else {
        reading.count_imu   += 1;
        reading.imu_pitch   += imu_pitch;
        reading.imu_roll    += imu_roll;
        reading.imu_yaw     += imu_yaw;
    }
  }

  counter++;
  

  leds.loop();
  transmitter.loop();
}