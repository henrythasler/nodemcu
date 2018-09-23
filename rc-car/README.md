# RC-Car sensor pod

Placing a ESP-based device into a RC-car to provide sensor data.

## Feature set

- Provide Wifi-AP 
- Integrate into local Wifi via end_user_setup()
- capture sensor data (tbd)
- write sensor data to SQLite-DB (in-memory)
- Provide webinterface with sensor information

## Prerequisites

1. clone this repo
2. git submodule update --init --recursive
3. Install python-dependency for esptool: `apt-get install python-serial`

## Install ESP-firmware

1. go to [nodemcu-build.com](https://nodemcu-build.com/) 
2. and create an image with the following modules: `adc, bit, crypto, dht, encoder, enduser_setup, file, gpio, http, mqtt, net, node, perf, pwm, rtctime, sjson, sntp, spi, sqlite3, struct, tmr, uart, websocket, wifi` 
3. Download the image (float-version)
4. Flash image: 
```
$ sudo ./esptool/esptool.py write_flash 0x00000 rc-car/image/nodemcu-master-23-modules-2018-09-23-09-01-43-float.bin 
    esptool.py v2.5.1-dev
    Found 2 serial ports
    Serial port /dev/ttyUSB0
    Connecting....
    Detecting chip type... ESP8266
    Chip is ESP8266EX
    Features: WiFi
    MAC: 01:02:03:04:05:06
    Uploading stub...
    Running stub...
    Stub running...
    Configuring flash size...
    Auto-detected Flash size: 4MB
    Flash params set to 0x0240
    Compressed 950272 bytes to 656268...
    Wrote 950272 bytes (656268 compressed) at 0x00000000 in 57.6 seconds (effective 131.9 kbit/s)...
    Hash of data verified.

    Leaving...
    Hard resetting via RTS pin...
```
5. Check with: `sudo ./uploader/nodemcu-uploader.py terminal` (press reset-button to reboot nodemcu)

```
--- Miniterm on /dev/ttyUSB0  115200,8,N,1 ---
--- Quit: Ctrl+] | Menu: Ctrl+T | Help: Ctrl+T followed by Ctrl+H ---
sl␀l��|␀�l�|␃␌␌␌�␌l�␄b|��␃�␒�s�c�␄c��gg�l'n���␄c␜x��l{drlp�o�␐␃␌␌�␌d␄␄␄␌␌␌c␌g�|␃�␄$�␌�c��nn�␀d��l`␂�␓␓nn␄$`␃␇␂gs���n␄␄{�`␂x�'�␐␃␄␄{�����␌␄␄␄c␌o�|␂␌�s���c��og�␀␌␌d`␃�␛␛ool�l`␃␎␃o{���g␌␌�dd`␃`�o␌␌␌��#�nd�␌��gg�␀␄�␇lp�o�␘␂␌␌s�����l�r�c␌'�|␃d䌇c��gn�␀d�␌l`␂�␓␓'nd�$`␃␇␂gs���n␄␄��␏d␇s��n␄␄��␏d��␃�␓�o�{��g|�␌d␄ddd`␃␜c�␒␂␌�|␂s�␃d�o�␌�g�␀␌l ␃��{�$�l␓�␌␌␌d`␃��{�l�l␓�␌␌␄d`␃��{�l␌��␀�␌␄dd`␃sl��rd���c␄��c␜|l␌c��␄␓���dc��o�␒gg�␘␃␄␃�l�|␃␌쇌␌l␌␄d�d�|�l␌�␏d�␃n�␀���c␌ll쌎␛␄b␄␃␃���b␌l␌�b␜rls


NodeMCU custom build by frightanic.com
	branch: master
	commit: 3661b8d5eb5b42ed2d5ff51fa8e9628c17270973
	SSL: false
	modules: adc,bit,crypto,dht,encoder,enduser_setup,file,gpio,http,mqtt,net,node,perf,pwm,sjson,sntp,spi,sqlite3,struct,tmr,uart,websocket,wifi
 build created on 2018-09-23 09:00
 powered by Lua 5.1.4 on SDK 2.2.1(6ab97e9)
lua: cannot open init.lua

```

## Download files

Go to folder: `cd rc-car`

### ESPlorer GUI

`sudo java -jar ../ESPlorer/ESPlorer.jar`

### Command line

Modify deploy.sh as you see fit then run `./deploy.sh`

- Remove files: `sudo ../uploader/nodemcu-uploader.py file remove init.lua config.lua flashdaemon.lua`
- Terminal: `sudo ../uploader/nodemcu-uploader.py terminal`

## References

- https://nodemcu-build.com/