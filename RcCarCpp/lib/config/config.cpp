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

int conf_transmit_all_interval_ms  = 50; // 50 times per second => 1000 / 20 = 50 
const char* conf_mqtt_topic_readings = "RcCar/acceleration";

bool        use_wifi = true;

// DNS Name of the Device:
const char *dns_name = "RcCar";