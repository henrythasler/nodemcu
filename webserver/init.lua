local cfg_file = "config"

-- compile config file
if file.open(cfg_file .. ".lua") then
  file.close()
  node.compile(cfg_file .. ".lua")
  file.remove(cfg_file .. ".lua")
end

-- load config from file
if file.open(cfg_file .. ".lc") then
  file.close()
  print( "config file found:" .. cfg_file .. ".lc" )
  dofile(cfg_file .. ".lc")
else
  print( "Config file not found. Using default values." )
  cfg={}
  cfg.wifi={}
  cfg.wifi.ssid="home"
  cfg.wifi.pwd="00000000"
  cfg.wifi.save=true
  cfg.hostname = "node01"
end


function wifi_monitor(config)
  connected = false
   tmr.alarm (1, 500, tmr.ALARM_AUTO, function ()
      if wifi.sta.getip ( ) == nil then
         print ("Waiting for Wifi connection")
         gpio.write(0,1-gpio.read(0));
         if connected == true then connected = false end
      else
         if connected ~= true then
           connected = true
           gpio.write( 0,0 )
           print( "Connected" )
           print( "IP: " .. wifi.sta.getip() )
           print( "Hostname: " .. wifi.sta.gethostname() )
           print( "Channel: " .. wifi.getchannel() )
         end
      end
   end)
end

-- setup general configuration
wifi.sta.sethostname( cfg.hostname )

-- Connect to existing station given in config
wifi.setmode( wifi.STATION )
wifi.sta.config( cfg.wifi )
wifi.sta.autoconnect( 1 )

-- monitor wifi connection and show status via LED
wifi_monitor()
collectgarbage()
