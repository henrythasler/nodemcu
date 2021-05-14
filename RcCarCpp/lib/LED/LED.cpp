#include "LED.h"


#define LED_ON  LOW
#define LED_OFF HIGH

void LED::setup(){
    pinMode(led_pin, OUTPUT); // Initialize the LED pin as an output
}

void LED::loop(unsigned long millis_now){
    if (blink_on_ms > 0){
        if (blink_count > 0){
            unsigned int elapsed_ms = millis_now - blink_last_action;
            if (elapsed_ms > blink_on_ms){
                if (blink_is_on){
                    digitalWrite(led_pin, LED_OFF); // Turn the LED off
                    blink_is_on = false;
                    blink_last_action = millis();
                    blink_count--;
                } else {
                    digitalWrite(led_pin, LED_ON); // Turn the LED on
                    blink_is_on = true;
                    blink_last_action = millis();
                    blink_count--;
                }
            }
        } else {
            blink_on_ms = 0;
        }
    }

    if (interval_on_ms > 0){
        unsigned long elapsed_ms = millis_now - interval_last_action;
        if (interval_is_on && elapsed_ms > interval_on_ms){
            digitalWrite(led_pin, LED_OFF); // Turn the LED off
            interval_is_on = false;
            interval_last_action = millis();
        } else if (!interval_is_on && elapsed_ms > interval_off_ms){
            digitalWrite(led_pin, LED_ON); // Turn the LED on
            interval_is_on = true;
            interval_last_action = millis();
        }
    }
    last_loop_millis = millis_now;
}

void LED::blink(unsigned int duration_on_ms){
    blink_on_ms = duration_on_ms;
    digitalWrite(led_pin, LED_ON); // Turn the LED on
    blink_is_on = true;
    blink_count = 1;
    blink_last_action = millis();
}
void LED::blink(unsigned int duration_on_ms, unsigned int repeat){
    blink_on_ms = duration_on_ms;
    digitalWrite(led_pin, LED_ON); // Turn the LED on
    blink_is_on = true;
    blink_count = 1; // + repeat * 2;
    blink_last_action = millis();
}
void LED::interval(unsigned int duration_on_ms, unsigned int duration_off_ms){
    // Store parameter;
    interval_on_ms  = duration_on_ms;
    interval_off_ms = duration_off_ms;
    // And Action:
    interval_is_on = true;
    interval_last_action = millis();
}

//  Blink Function for Feedback of Status, takes about 1000ms
void LED::blinkBlocking(int count, int duration_on, int duration_off)
{
    for (int i = 0; i < count; i++)
    {
        digitalWrite(led_pin, LED_ON); // Turn the LED on
        delay(duration_on);
        digitalWrite(led_pin, LED_OFF); // Turn the LED off by making the voltage LED_OFF
        delay(duration_off);
    }
}
