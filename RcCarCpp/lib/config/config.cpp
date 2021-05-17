#include "config.h"

bool conf_debug                   = false;
bool conf_debug_serial            = false; // Print the raw values of the sensor to serial
bool conf_restart_wifi_issue      = true;
int  conf_wifi_reset_after_ms     = 9000;
int  conf_mqtt_reset_after_ms     = 5000;

// MQTT Settings:
const char *mqtt_broker_url = "base.wlan";
const int   mqtt_broker_port = 1883;
const char* mqtt_client_name = "RcCar";

int conf_transmit_all_interval_ms  = 20; // 50 times per second => 1000 / 20 = 50 
float conf_sample_freq_hz = 1000 / (float) conf_transmit_all_interval_ms;
float conf_sample_delta_sec = 1.0f / (float) conf_sample_freq_hz;
const char* conf_mqtt_topic_readings = "RcCar/acceleration";

int conf_imu_sample_interval_ms = 20; // if set to same value as conf_transmit_all_interval_ms, the computation is based on the averaged values in last interval! perferable!
float conf_imu_sample_freq_hz =   1000 / (float) conf_imu_sample_interval_ms;
float conf_imu_sample_delta_sec = 1.0f / conf_imu_sample_freq_hz;

bool        use_wifi = false;

// DNS Name of the Device:
const char *dns_name = "RcCar";