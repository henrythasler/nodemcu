-- init mqtt client with keepalive timer 120sec
m = mqtt.Client(cfg.hostname, 120, "user", "password")

-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline"
-- to topic "/lwt" if client don't send keepalive packet
m:lwt("/lwt", cfg.hostname.." offline", 0, 0)

m:on("connect", function(client) print ("MQTT-Broker connected") end)
m:on("offline", function(client) print ("MQTT-Broker offline") end)

-- on publish message receive event
m:on("message", function(client, topic, data)
  print(topic .. ":" )
  if data ~= nil then
    print(data)
  end
end)

-- calculate natural logarithm
function log(x)
  local xm = (x-1.)/(x+1.)
  local n = 20
  local result=0.
  for k=0,n do
    result = result + 2./(2.*k+1)*xm^(2*k+1)
  end
--  local residual = ((x-1.)^2)/(2*(2*n+3)*math.abs(x))*math.abs(xm)^(2*n-1)
--  result = result + residual
  return result
end

-- calculate average value of array (table)
function average(data)
  local sum = 0
  for i = 1, #data do
    sum = sum + data[i]
  end
  return (sum/#data)
end

local counter = 0
local sample_interval = 5
local transmit_interval = 30
local ringbuffer = {pos=1, size=20, data={}}

-- for TLS: m:connect("192.168.11.118", secure-port, 1)
m:connect(cfg.mqtt.broker.host, cfg.mqtt.broker.port, 0,
      function(client)
        print("MQTT - connected to ".. cfg.mqtt.broker.host..":"..cfg.mqtt.broker.port)
        --m:subscribe("flash",0, function(conn) print("subscribe success") end)

        tmr.alarm (1, sample_interval*1000, tmr.ALARM_AUTO, function ()
          ringbuffer.data[ringbuffer.pos] = adc.read(0)
          ringbuffer.pos = ringbuffer.pos + 1
          if ringbuffer.pos > ringbuffer.size then ringbuffer.pos = 1 end
          --raw = adc.readvdd33()

          --print(json)
          if counter == 0 then
            local data = {}
            sec, usec = rtctime.get()
            
            local raw = average(ringbuffer.data) 
            data.timestamp = sec
            data.raw = tonumber(string.format("%.2f", raw))
            data.voltage = (raw*0.0008870693-0.011525455)*(328.+92.)/92.
            data.voltage = tonumber(string.format("%.4f", data.voltage))
            data.value = 3528.15*298.15 / (3528.15 + log( (5.-data.voltage)*2440./(data.voltage*1000.) )*298.15) - 273.15
            data.value = tonumber(string.format("%.1f", data.value))
            data.unit = "°C"
            sensordata.outside.temperature = data.value
            ok, json = pcall(cjson.encode, data)
            if not ok then
              print("failed to encode!")
            end
          
            m:publish("home/out/temp",json,0,1)
            m:publish("home/out/temp/value",data.value,0,1)
          end
          counter = counter + sample_interval
          if counter >= transmit_interval then counter = 0 end
        end)
      end,
      function(client, reason)
        print("MQTT - error connecting to "..cfg.mqtt.broker.host..cfg.mqtt.broker.port..": "..reason)
      end)
