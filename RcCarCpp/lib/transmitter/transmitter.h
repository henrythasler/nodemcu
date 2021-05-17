#ifndef __transmitter_H
#define __transmitter_H

#include <PubSubClient.h>
#include <LED.h>
#include <LEDS.h>
#include "config.h"
#include "static.h"

struct Readings {
    int    count;
    int    count_imu;
    unsigned long m_first;
    unsigned long m_last;
    double pitch;
    double roll;
    double yaw;
    double imu_pitch;
    double imu_roll;
    double imu_yaw;
    double acc_x;
    double acc_y;
    double acc_z;
    double ang_x;
    double ang_y;
    double ang_z;
    double gyro_x;
    double gyro_y;
    double gyro_z;
    double temp;
};

class Transmitter {
    private:
        PubSubClient* mqtt_client;
        LEDs* leds_;
        Readings* readings_;
        
        unsigned long last_transmit_ms = 0;
        int last_tx_ms = -1;
    public:
        char json_buffer[json_buffer_size];
        char print_buffer[print_buffer_size];
    private:
        void transmitAll(unsigned long millis_now);
        void transmit_mqtt_internal(const char *topic, const char *msg, bool retained);
    public:
        Transmitter(PubSubClient* client_, Readings* readings_t, LEDs* leds_t){
            this->mqtt_client = client_;
            leds_ = leds_t;
            this->readings_ = readings_t;
        }
        void transmit_mqtt_msg(const char *topic, const char *msg);
        void transmit_retained_mqtt_msg(const char *topic, const char *msg);
        void reconnect_mqtt();

        char* getReadingsTopic(int meter);
        void loop();
};

#endif