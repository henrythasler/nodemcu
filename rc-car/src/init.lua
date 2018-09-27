function compile_lua(filename)
  if file.exists(filename .. ".lua") then
    node.compile(filename .. ".lua")
    file.remove(filename .. ".lua")
    collectgarbage()
    return true
  else
    return false
  end
end

function run_lc(filename)
  if file.exists(filename .. ".lc") then
    dofile( filename .. ".lc" )
    return true
  else
    print("[init-lua] - " .. filename .. ".lc not found." )
    return false
  end
end

function run_lua(filename)
  if file.exists(filename .. ".lua") then
    dofile( filename .. ".lua" )
    return true
  else
    print("[init-lua] - " .. filename .. ".lua not found." )
    return false
  end
end

function start_runnables()
  for _, item in ipairs(cfg.runnables.active) do
    print("starting "..item)
    dofile(item .. ".lc")
--    if pcall(run_lc, item) then
--      print("starting "..item)
--    else
--      print('Error running '..item)
--    end
  end
end

function wifi_monitor(config)
  local connected = false
  local retry = 0
  tmr.alarm (0, 1000, tmr.ALARM_AUTO, function ()
    if wifi.sta.getip ( ) == nil then
        print ("Waiting for WLAN connection to '" ..cfg.wifi.ssid.."'")
        retry = retry+1
        gpio.write(0,1-gpio.read(0));
        if(retry > 10) then node.restart() end
        if connected == true then
          connected = false
          node.restart()
          end
    else
      if connected ~= true then
        connected = true
        gpio.write( 0,0 )
        print( "WLAN - connected" )
        print( "IP: " .. wifi.sta.getip() )
        print( "Hostname: " .. wifi.sta.gethostname() )
        print( "Channel: " .. wifi.getchannel() )
        print( "Signal Strength: " .. wifi.sta.getrssi())
        mdns.register(cfg.hostname, { description="CDC rocks", service="http", port=80, location="Earth" })
        print( "mDNS: "..cfg.hostname..".local")
        start_runnables()
      end
      if cfg.ntp.server and cfg.ntp.synced == false then
        sntp.sync(cfg.ntp.server,
          function(sec,usec,server)
            tm = rtctime.epoch2cal(rtctime.get())
            date =string.format("%04d-%02d-%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"])
            print(string.format("ntp sync with %s ok: %s UTC/GMT", server, date))
            cfg.ntp.synced = true
          end,
          function(err)
            print('failed! '..err)
            cfg.ntp.synced = false
          end
        )
      end
    end
  end)
end

function ap_monitor()
  -- register some debug callbacks
  wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, function(T)
    print("[SOFTAP] - client connected ("..T.MAC..")")
  end)

  wifi.eventmon.register(wifi.eventmon.AP_STADISCONNECTED, function(T)
    print("[SOFTAP] - disconnected ("..T.MAC..")")
  end)

end

-- ### main part
local cfg_file = "config"

-- compile config file
compile_lua(cfg_file)

-- load config from file
if run_lc(cfg_file) == false then
  print("[init-lua] - Config file not found. Using default values." )
  cfg={}
  cfg.wifi = {}
  cfg.wifi.ssid = "CDC"
  cfg.wifi.pwd = ""
  cfg.wifi.auth = wifi.OPEN
  cfg.wifi.channel = 6
  cfg.wifi.hidden = false
  cfg.wifi.max = 4
  cfg.wifi.save = false

  cfg.hostname = "node02"

  cfg.runnables = {}
  cfg.runnables.sources = {}

  cfg.ntp = {}
  cfg.ntp.server = false
end

cfg.runnables.active = {}
cfg.ntp.synced = false


-- build runnables
for _, item in ipairs(cfg.runnables.sources) do
  print("preparing "..item)
  local status, error = pcall(compile_lua, item)
  if status == true then
    table.insert(cfg.runnables.active, item)
  else
    print('Error compiling '..item..": "..error)
  end
end

-- setup general configuration
wifi.sta.sethostname( cfg.hostname )

-- Set-up Wifi AP
wifi.setmode( cfg.wifi.mode )

if cfg.wifi.mode == wifi.SOFTAP then 
  print("[init-lua] - setting up SoftAP...")
  wifi.ap.config(cfg.wifi)
  wifi.ap.setip(cfg.net)
  mdns.register(cfg.hostname, { description="CDC rocks", service="http", port=80, location="Earth" })
  start_runnables()

elseif cfg.wifi.mode == wifi.STATION then 
  print("[STATION] - Connecting to AP...")
  wifi.sta.config( cfg.wifi )
  wifi.sta.connect()
  wifi_monitor()
end

