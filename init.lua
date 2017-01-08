function compile_lua(filename)
  if file.open(filename .. ".lua") then
    file.close()
    node.compile(filename .. ".lua")
    file.remove(filename .. ".lua")
    return true
  else
    return false
  end
end

function run_lc(filename)
  if file.open( filename .. ".lc" ) then
    file.close()
    dofile( filename .. ".lc" )
    return true
  else
    print( filename .. ".lc not found." )
    return false
  end
end

function run_lua(filename)
  if file.open( filename .. ".lua" ) then
    file.close()
    dofile( filename .. ".lua" )
    return true
  else
    print( filename .. ".lua not found." )
    return false
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

        for _, item in ipairs(cfg.runnables.active) do
          if pcall(run_lc, item) then
            print("starting "..item)
          else
            print('Error running '..item)
          end
        end
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


-- ### main part
local cfg_file = "config"

-- compile config file
compile_lua(cfg_file)

-- load config from file
if run_lc(cfg_file) == false then
  print( "Config file not found. Using default values." )
  cfg={}
  cfg.wifi={}
  cfg.wifi.ssid="home"
  cfg.wifi.pwd="00000000"
  cfg.wifi.save=true
  cfg.hostname = "node01"
  cfg.runnables = {}
  cfg.runnables.sources = {}
  cfg.ntp = {}
  cfg.ntp.server = false
end

cfg.runnables.active = {}
cfg.ntp.synced = false

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

-- Connect to existing station given in config
wifi.setmode( wifi.STATION )
wifi.sta.config( cfg.wifi )
wifi.sta.connect()

sensordata = {}
sensordata.outside = {}

-- monitor wifi connection and show status via LED
wifi_monitor()

collectgarbage()
