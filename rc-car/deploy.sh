#! /bin/bash
sudo ./../uploader/nodemcu-uploader.py \
    upload \
        src/config.lua:config.lua \
        src/init.lua:init.lua \
        src/status.lua:status.lua \
        src/webserver.lua:webserver.lua \
        src/MPU6050.lua:MPU6050.lua \
        ../flash/flashdaemon.lua:flashdaemon.lua \
#    --verify=sha1