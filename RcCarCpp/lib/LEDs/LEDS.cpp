#include "LEDS.h"

void LEDs::setup(){
    led_int.setup();
}

void LEDs::loop(){
    unsigned long millis_now = millis();
    led_int.loop(millis_now);
}