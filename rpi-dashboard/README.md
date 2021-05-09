# Introduction

# Hardware

## Parts

- [Raspberry Pi 4 Computer Modell B, 4GB RAM](https://www.berrybase.de/raspberry-pi/raspberry-pi-computer/boards/raspberry-pi-4-computer-modell-b-4gb-ram?c=319)
- [Geekworm Raspberry Pi 4 Aluminum Case](https://www.amazon.de/Geekworm-Raspberry-Aluminum-Passive-Dissaption/dp/B07ZVJDRF3)
- [LABISTS Raspberry Pi 4 Type C 5.1V 3A](https://www.amazon.de/LABISTS-Raspberry-Type-C-Kabel-Schwarz/dp/B07ZCK2B8J)
- [5 Zoll kapazitiver Touchscreen für Raspberry Pi](https://www.amazon.de/kapazitiver-Touchscreen-Raspberry-4-800x480-Unterstützung/dp/B07ZD4QGQJ)
- [GY-BME280 Breakout Board](https://www.berrybase.de/sensoren-module/feuchtigkeit/gy-bme280-breakout-board-3in1-sensor-f-252-r-temperatur-luftfeuchtigkeit-und-luftdruck?c=92)
- [40pin Jumper](https://www.berrybase.de/raspberry-pi/raspberry-pi-computer/kabel-adapter/gpio-csi-dsi-kabel/40pin-jumper/dupont-kabel-female-150-female-trennbar)

## Setup

![Breadboard](docs/rpi-breadboard.png)

# Software
## Operating System

1. Use the [Raspberry Pi Imager](https://www.raspberrypi.org/software/) to install `Raspberry Pi OS with desktop`.
2. Alternative: download [Raspberry Pi OS with desktop](https://www.raspberrypi.org/software/operating-systems/) and flash to disk (use [Startup Disc Creator](https://help.ubuntu.com/stable/ubuntu-help/addremove-creator.html) or `sudo dd if=2021-03-04-raspios-buster-armhf.img of=/dev/sdx bs=4M`, make sure to use the correct device)
3. `sudo raspi-config`: 
- `Interface Options` -> enable `P3 VNC`
- `Display Options` -> `Resolution` -> `Mode 9 (800x600)`
4. `sudo rebooot now`
5. [Install Node-RED](https://nodered.org/docs/getting-started/raspberrypi)


# References

