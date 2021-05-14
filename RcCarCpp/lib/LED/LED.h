#ifndef __LED_H
#define __LED_H

#include <Arduino.h>


class LED {
    private:
        uint8_t led_pin;

        unsigned long last_action = 0;
        unsigned long last_loop_millis = millis();

        unsigned long blink_last_action = 0;
        bool          blink_is_on  = 0;
        unsigned int  blink_count  = 0;
        unsigned int  blink_on_ms  = 0;

        unsigned long interval_last_action = 0;
        bool          interval_is_on  = 0;
        unsigned int  interval_on_ms  = 0;
        unsigned int  interval_off_ms = 0;

    public:
        LED(uint8_t led_pin_t){ led_pin = led_pin_t; };
        void setup();
        void loop(unsigned long millis_now);

        void blink(unsigned int duration_on_ms);
        void blink(unsigned int duration_on_ms, unsigned int repeat);
        void interval(unsigned int duration_on_ms, unsigned int duration_off_ms);

        void blinkBlocking(int count, int durationon, int durationoff);
};

#endif