cfg={}

-- WIFI
cfg.wifi = {}
cfg.wifi.mode = wifi.SOFTAP -- or wifi.STATION
cfg.wifi.ssid = "CDC"
cfg.wifi.pwd = "00000000"
cfg.wifi.auth = wifi.OPEN 
cfg.wifi.channel = 6
cfg.wifi.hidden = false
cfg.wifi.max = 4
cfg.wifi.save = false

-- nodemcu
-- hostname: name of this nodemcu
cfg.hostname = "node02"

-- Runnables
cfg.runnables = {}
cfg.runnables.sources = {"httpserver", "sensor"}

-- MQTT
-- host: host name or ip of the broker
-- port: port where the broker can be reached
cfg.mqtt = {}
cfg.mqtt.broker = {}
cfg.mqtt.broker.host = "192.168.178.10"
cfg.mqtt.broker.port = 1883

-- NTP
-- cfg.ntp.server: IP address of NTP provider. Set to 'false' to disable sync
cfg.ntp = {}
cfg.ntp.server = '192.168.178.1'
