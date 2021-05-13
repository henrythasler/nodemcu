# Introduction

![Dashboard](docs/dashboard.png)

# Hardware

## Parts

- [Raspberry Pi 4 Computer Modell B, 4GB RAM](https://www.berrybase.de/raspberry-pi/raspberry-pi-computer/boards/raspberry-pi-4-computer-modell-b-4gb-ram?c=319)
- [Geekworm Raspberry Pi 4 Aluminum Case](https://www.amazon.de/Geekworm-Raspberry-Aluminum-Passive-Dissaption/dp/B07ZVJDRF3)
- [LABISTS Raspberry Pi 4 Type C 5.1V 3A](https://www.amazon.de/LABISTS-Raspberry-Type-C-Kabel-Schwarz/dp/B07ZCK2B8J)
- [5 Zoll kapazitiver Touchscreen für Raspberry Pi](https://www.amazon.de/kapazitiver-Touchscreen-Raspberry-4-800x480-Unterstützung/dp/B07ZD4QGQJ)
- [GY-BME280 Breakout Board](https://www.berrybase.de/sensoren-module/feuchtigkeit/gy-bme280-breakout-board-3in1-sensor-f-252-r-temperatur-luftfeuchtigkeit-und-luftdruck?c=92)
- [40pin Jumper](https://www.berrybase.de/raspberry-pi/raspberry-pi-computer/kabel-adapter/gpio-csi-dsi-kabel/40pin-jumper/dupont-kabel-female-150-female-trennbar)

## Setup

Connect either BME280 or BMP180. E-Version is with humidity sensor and 280 is the next-gen 180 with better performance.

![Breadboard](docs/rpi-breadboard.png)

# Software
## Operating System

1. Use the [Raspberry Pi Imager](https://www.raspberrypi.org/software/) to install `Raspberry Pi OS with desktop`.
2. Alternative: download [Raspberry Pi OS with desktop](https://www.raspberrypi.org/software/operating-systems/) and flash to disk (use [Startup Disc Creator](https://help.ubuntu.com/stable/ubuntu-help/addremove-creator.html) or `sudo dd if=2021-03-04-raspios-buster-armhf.img of=/dev/sdx bs=4M`, make sure to use the correct device)
3. `sudo raspi-config`: 
- `Interface Options` -> enable `P3 VNC` and `P5 I2C`
- `Display Options` -> `Resolution` -> `Mode 9 (800x600)`
4. `sudo rebooot now`

## User Interface

1. [Install Node-RED](https://nodered.org/docs/getting-started/raspberrypi)
2. Install mosquitto MQTT Broker: 
 - `sudo apt-get install mosquitto mosquitto-clients`
 - Test with: `mosquitto_sub -h localhost -t \$SYS/broker/bytes/#`
3. Open node-red in a browser (`http://raspberrypi:1880/`) and import `flows.json`.

## Kiosk Mode

`sudo apt install unclutter`

`nano /home/pi/kiosk.sh`
```sh
#!/bin/bash
xset s noblank
xset s off
xset -dpms

unclutter -idle 0.5 -root &

sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences
/usr/bin/chromium-browser --noerrdialogs --disable-infobars --kiosk http://localhost:1880/ui &

while true; do
      sleep 1
done
```
Make it executable: `chmod +x /home/pi/kiosk.sh`

run `echo $DISPLAY` from a GUI-shell (NOT ssh-session) and use the result in the following file:

`sudo nano /etc/systemd/system/kiosk.service`:
```ini
[Unit]
Description=Chromium_Kiosk
Wants=graphical.target
After=graphical.target

[Service]
Environment=DISPLAY=:0.0
Environment=XAUTHORITY=/home/pi/.Xauthority
Type=simple
ExecStart=/bin/bash /home/pi/kiosk.sh
Restart=on-abort
User=pi
Group=pi

[Install]
WantedBy=graphical.target
```

enable on boot: `sudo systemctl enable kiosk.service` 

start: `sudo systemctl start kiosk.service`
stop: `sudo systemctl stop kiosk.service`

## Application Icon

`sudo nano /usr/share/applications/Dashboard.desktop`

```
[Desktop Entry]
Version=1.0
Exec=sudo systemctl start kiosk
Name=Dashboard
Encoding=UTF-8
Terminal=true
Type=Application
Categories=Application;Network;
Icon=ksysguard
```

The Dashboard can be found in the Internet Section:

![Dashboard](docs/dashboard-menu.png)

# References

- [Raspberry Pi Pinout](https://pinout.xyz/pinout/i2c#)
- [Raspberry Pi Kiosk using Chromium](https://pimylifeup.com/raspberry-pi-kiosk/)

sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences