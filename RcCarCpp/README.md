
## Setup
- Open with VSCode with PlatformIO installed
- Run "node set_wifi.js" for creating the config file for WiFi
- Compile & Flash by going to PlatformIO Button and hit "Upload and Monitor"

## Monitoring Setup
- You might have to update the tty info in platform.ini
- Modify the following two lines according to the tty that matches your operating system tty
- monitor_port = /dev/tty.wchusbserial1420
- upload_port = /dev/tty.wchusbserial1420

## Parmeters
- Have a look at lib/config/config.cpp
- Change the IP of the MQTT Server and other paramters here


# Observations:
- Tests showed:
 - at least for yaw, the "normal" yaw has less drift as the imu_yaw (with quaternation filter).
 - for yaw, the "yaw" value has better accuracy in degrees compared to reality compared to imu_yaw
 - Use ang_x and ang_y for acceleration in x/y direction!
