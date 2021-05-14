#ifndef __LEDS_H
#define __LEDS_H

#include <LED.h>
#include <Arduino.h>

class LEDs {
    private:
        unsigned long last_loop_millis = millis();
    public:
        LED led_int = LED(LED_BUILTIN); // the internal LED of the board. Mostly a Blue one!
        void setup();
        void loop();
};

#endif