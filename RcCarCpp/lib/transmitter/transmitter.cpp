
#include "transmitter.h"
#include <Arduino.h>
#include <config.h>
#include <JsonObjectStr.h>
#include <Helper.h>
          
// # Note: max Packet size is 128 characters (MQTT_MAX_PACKET_SIZE)!
// Where: MQTT_MAX_HEADER_SIZE = 5
// Packet size is: MQTT_MAX_HEADER_SIZE + 2 + strlen(topic) + plength
// => ca. 120 characters for topic and payload !!!
void Transmitter::transmit_mqtt_msg(const char *topic, const char *msg)
{
    transmit_mqtt_internal(topic,msg, false);
}
// -> will be available to mqtt clients directly after connect
void Transmitter::transmit_retained_mqtt_msg(const char *topic, const char *msg){
    transmit_mqtt_internal(topic,msg, true);
}

// retained = true makes the message retained -> will be available to mqtt clients directly after connect
void Transmitter::transmit_mqtt_internal(const char *topic, const char *msg, bool retained)
{
    if (use_wifi){
        if (!mqtt_client->connected())
        {
            reconnect_mqtt();
        }
        if (mqtt_client->connected()){
            if (conf_debug) {
                Serial.printf("=> Transmit MQTT, len: %d\n", strlen(msg));
            }
            bool success = mqtt_client->publish(topic, msg, retained); 
            if (!success)
            {
                Serial.println("Mqtt transmit failed");
            }
        }
    }
}

void Transmitter::reconnect_mqtt()
{
    // was connected, is not any more, inform ... (nothing to inform)

    // Now try to reconnect
    int reconnect_count = 0;
    unsigned long t_start = millis();
    if (use_wifi){
        while (!mqtt_client->connected())
        {
            Serial.print("MQTT Reconnecting...");
            reconnect_count++;

            bool connected = mqtt_client->connect(mqtt_client_name); // blocks quite some time!
            if (!connected)
            {
                if ((millis() - t_start) > (unsigned long) conf_mqtt_reset_after_ms){
                    if (conf_restart_wifi_issue){
                        Serial.println("MQTT reconnect failed! Restart ESP!");
                        ESP.restart();
                    } else {
                        Serial.println("MQTT reconnect failed! Resume ...!");
                        break;
                    }
                }
                Serial.print("MQTT failed, rc=");
                Serial.print(mqtt_client->state());
                Serial.printf(" -> retrying in %d seconds\n", reconnect_count);
                leds_->led_int.blinkBlocking(2, 50, 50);
                delay(reconnect_count < 3 ? 250 : 500);
            }
        }
    }

    if (mqtt_client->connected()){
        Serial.printf("MQTT Connected after %d attempts\n", reconnect_count);
    }
}

void Transmitter::loop(){
    unsigned long millis_now = millis();
    int elapsed_since_tx = millis_now - last_transmit_ms;
    if (elapsed_since_tx < 0) {
        elapsed_since_tx = 0; // overflow handing (should not happen however due to overflow arithmetic!)
        last_transmit_ms = millis_now;
    }

    if (elapsed_since_tx > conf_transmit_all_interval_ms){
        last_transmit_ms = millis_now;
        transmitAll(millis_now);
    }
}

void Transmitter::transmitAll(unsigned long millis_now){
    JsonObjectStr json(json_buffer, json_buffer_size);

    int count = readings_->count;
    readings_->acc_x = readings_->acc_x / count;
    readings_->acc_y = readings_->acc_y / count;
    readings_->acc_z = readings_->acc_z / count;

    readings_->ang_x = readings_->ang_x / count;
    readings_->ang_y = readings_->ang_y / count;
    readings_->ang_z = readings_->ang_z / count;

    readings_->gyro_x = readings_->gyro_x / count;
    readings_->gyro_y = readings_->gyro_y / count;
    readings_->gyro_z = readings_->gyro_z / count;

    readings_->yaw   = readings_->yaw / count;
    readings_->roll  = readings_->roll / count;
    readings_->pitch = readings_->pitch / count;

    readings_->temp = readings_->temp / count;

    json.add("temp", readings_->temp);

    json.add("yaw", readings_->yaw);
    json.add("roll", readings_->roll);
    json.add("pitch", readings_->pitch);

    json.add("gyro_x", readings_->gyro_x);
    json.add("gyro_y", readings_->gyro_y);
    json.add("gyro_z", readings_->gyro_z);

    json.add("ang_x", readings_->ang_x);
    json.add("ang_y", readings_->ang_y);
    json.add("ang_z", readings_->ang_z);

    json.add("acc_x", readings_->acc_x);
    json.add("acc_y", readings_->acc_y);
    json.add("acc_z", readings_->acc_z);

    json.add("millis_start", readings_->m_first);
    json.add("millis_end", readings_->m_last);
    json.add("count", readings_->count);

    // json.add("acc_quer", millisSinceStart());
    json.finalize();
            
    transmit_mqtt_msg(conf_mqtt_topic_readings, json.getBuff());
    json.free();
    last_tx_ms = millis() - millis_now;
    if (conf_debug){
        Serial.printf("TransmitAll in %d ms\n", last_tx_ms);
    }

    if (conf_debug_serial){
        Serial.print(readings_->count);
        Serial.print('\t');
        Serial.print(millis());
        Serial.print('\t');
        Serial.print(readings_->pitch, 3);
        Serial.print('\t');
        Serial.print(readings_->roll, 3);
        Serial.print('\t');
        Serial.print(readings_->yaw, 3);
        Serial.print("\t| ");
        Serial.print(readings_->acc_x, 3);
        Serial.print('\t');
        Serial.print(readings_->acc_y, 3);
        Serial.print("\t-| ");
        Serial.print(readings_->ang_x, 3);
        Serial.print('\t');
        Serial.print(readings_->ang_x, 3);
        Serial.print("\t| ");
        Serial.print(readings_->temp, 3);
        Serial.println();
    }

    readings_->count = 0;
}

