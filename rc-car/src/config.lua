cfg={}

-- WIFI
cfg.wifi = {}
cfg.wifi.mode = wifi.SOFTAP -- or wifi.SOFTAP / wifi.STATION 
cfg.wifi.ssid = "CDC"
cfg.wifi.pwd = "00000000"
cfg.wifi.auth = wifi.OPEN 
cfg.wifi.channel = 6
cfg.wifi.hidden = false
cfg.wifi.max = 4
cfg.wifi.save = false

cfg.net = {}
cfg.net.ip = "192.168.1.1"
cfg.net.netmask="255.255.255.0"
cfg.net.gateway="192.168.1.1"

-- nodemcu
-- hostname: name of this nodemcu
cfg.hostname = "car"

-- Runnables
cfg.runnables = {}
cfg.runnables.sources = {"flashdaemon", "webserver", "MPU6050"}

-- NTP
-- cfg.ntp.server: IP address of NTP provider. Set to 'false' to disable sync
cfg.ntp = {}
cfg.ntp.server = false