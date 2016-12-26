# nodemcu
stuff you would need to play with a nodemcu (ESP8266) iot device

# how to git

    $ git clone https://github.com/henrythasler/nodemcu.git
    $ cd nodemcu
    $ git remote add nodemcu https://github.com/henrythasler/nodemcu.git
    // do something
    $ git add .
    $ git commit -a
    $ git push nodemcu master


# install nodejs
```
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt install nodejs
```

# module overview

* `init.lua` - Main script. Handles Wifi connection and calls other modules
* `config.lua` - all config data is stored in this file

### `/flash`
 * `flashdaemon.lua` - lua-script to handle file uploads, commands. Returns a status-html. Run that file on your nodemcu after wifi is connected.
 * `status.lua` - generate status.html on nodemcu. Called by `flashdaemon.lua`.

### `/sensor`
 * `temperature.lua` - convert reading from ADC0 to temperature value and send result to MQTT broker.

### `/webserver`
 * `httpserver.lua` - provides sensor data as JSON.
