cfg={}

-- WIFI
cfg.wifi = {}
cfg.wifi.ssid = "home"
cfg.wifi.pwd = "0000"
cfg.wifi.save = false

-- nodemcu
-- hostname: name of this nodemcu
cfg.hostname = "node01"

-- Runnables
cfg.runnables = {}
cfg.runnables.sources = {"flashdaemon", "temperature"}

-- MQTT
-- host: host name or ip of the broker
-- port: port where the broker can be reached
cfg.mqtt = {}
cfg.mqtt.broker = {}
cfg.mqtt.broker.host = "192.168.178.31"
cfg.mqtt.broker.port = 1883

-- NTP
-- cfg.ntp.server: IP address of NTP provider. Set to 'false' to disable sync
cfg.ntp = {}
cfg.ntp.server = '192.168.178.1'
