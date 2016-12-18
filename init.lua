local cfg_file = "config"

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

function wifi_monitor(config)
  local connected = false
   tmr.alarm (1, 1000, tmr.ALARM_AUTO, function ()
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

          sntp.sync('192.168.178.1',
            function(sec,usec,server)
              tm = rtctime.epoch2cal(rtctime.get())
              date =string.format("%04d-%02d-%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"])
              print(string.format("ntp sync with %s ok: %s UTC/GMT", server, date))
            end,
            function(err)
              print('failed! '..err)
            end
          )

           -- run http server
           if run_lc( "httpserver" ) == false then
             print( "Script not found: httpserver" )
           end

           -- run sensors
           if run_lc( "temperature" ) == false then
             print( "Script not found: temperature" )
           end

         end
      end
   end)
end


-- ### main part

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
end

compile_lua("httpserver")
compile_lua("temperature")

-- setup general configuration
wifi.sta.sethostname( cfg.hostname )

-- Connect to existing station given in config
wifi.setmode( wifi.STATION )
wifi.sta.config( cfg.wifi )
wifi.sta.autoconnect( 1 )

-- monitor wifi connection and show status via LED
-- setup other servers on connect
httpserver = nil

sensordata = {}
sensordata.outside = {}

wifi_monitor()

collectgarbage()
