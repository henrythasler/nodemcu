-- init mqtt client with keepalive timer 120sec
m = mqtt.Client(cfg.hostname, 120, "user", "password")

-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline"
-- to topic "/lwt" if client don't send keepalive packet
m:lwt("/lwt", cfg.hostname.." offline", 0, 0)

m:on("connect", function(client) print ("connected") end)
m:on("offline", function(client) print ("offline") end)

-- on publish message receive event
m:on("message", function(client, topic, data)
  print(topic .. ":" )
  if data ~= nil then
    print(data)
  end
end)

-- for TLS: m:connect("192.168.11.118", secure-port, 1)
m:connect(cfg.mqtt.broker.host, cfg.mqtt.broker.port, 0,
      function(client)
        print("MQTT - connected to ".. cfg.mqtt.broker.host..":"..cfg.mqtt.broker.port)
        tmr.alarm (1, 10000, tmr.ALARM_AUTO, function ()
          raw = adc.read(0)
          --raw = adc.readvdd33()

          local data = {}
          data.timestamp = tmr.now()
          data.raw = raw
          data.voltage = raw/1024*3.3
          data.value = 3528.15*298.15 / (3528.15 + math.floor( (1024-raw)*2440/(raw*1000) )*298.15 )
          data.unit = "°C"
          sensordata.outside.temperature = data.value..data.unit
          ok, json = pcall(cjson.encode, data)
          if not ok then
            print("failed to encode!")
          end

          m:publish("sensor/outside/temperature",json,0,1)
        end)
      end,
      function(client, reason)
        print("MQTT - error connecting to "..cfg.mqtt.broker.host..cfg.mqtt.broker.port..": "..reason)
      end)
