#! /bin/bash
sudo ./../uploader/nodemcu-uploader.py upload src/init.lua:init.lua src/config.lua:config.lua src/httpserver.lua:httpserver.lua --verify=sha1