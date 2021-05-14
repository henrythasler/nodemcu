#ifndef __CONFIG_H
#define __CONFIG_H

#include <Arduino.h>

extern bool conf_debug; // can be set to true via http request
extern bool conf_debug_serial;
extern bool conf_restart_wifi_issue;
extern int  conf_wifi_reset_after_ms;
extern int  conf_mqtt_reset_after_ms;

// MQTT SEttings:
extern const char *mqtt_broker_url;
extern const int   mqtt_broker_port;
extern const char* mqtt_client_name;

extern int conf_transmit_all_interval_ms;
extern const char* conf_mqtt_topic_readings;

extern bool   use_wifi;
extern const char *dns_name;

#endif