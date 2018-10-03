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
        dofile(filename .. ".lc")
        return true
    else
        print("[init] - " .. filename .. ".lc not found.")
        return false
    end
end

function start_runnables()
    for _, item in ipairs(cfg.runnables.active) do
        --if file.exists(item .. ".lc") then
        --    dofile(item .. ".lc")
        --else
        --    print("[init] - " .. item .. ".lc not found.")
        --end
        if pcall(run_lc, item) then
            print("[init] - started " .. item)
        else
            print("![init] - Error running " .. item)
        end
    end
end

function wifi_monitor(config)
    local connected = false
    local retry = 0
    tmr.alarm(
        0,
        2000,
        tmr.ALARM_AUTO,
        function()
            if wifi.sta.getip() == nil then
                print("[init] - Waiting for WiFi connection to '" .. cfg.wifi.ssid .. "'")
                retry = retry + 1
                gpio.write(4, 1 - gpio.read(4))
                if (retry > 10) then
                    node.restart()
                end
                if connected == true then
                    connected = false
                    node.restart()
                end
            else
                stats.heap = (stats.heap + node.heap())/2
                print(string.format("[init] - %u Bytes free", node.heap()))
                if connected ~= true then
                    connected = true
                    gpio.write(4, 0)
                    print("[init] - \tWiFi - connected")
                    print("[init] - \tIP: " .. wifi.sta.getip())
                    print("[init] - \tHostname: " .. wifi.sta.gethostname())
                    print("[init] - \tChannel: " .. wifi.getchannel())
                    print("[init] - \tSignal Strength: " .. wifi.sta.getrssi())
                    mdns.register(
                        cfg.hostname,
                        {description = "CDC rocks", service = "http", port = 80, location = "Earth"}
                    )
                    print("[init] - \tmDNS: " .. cfg.hostname .. ".local")
                    start_runnables()
                end
                if cfg.ntp.server and cfg.ntp.synced == false then
                    sntp.sync(
                        cfg.ntp.server,
                        function(sec, usec, server)
                            tm = rtctime.epoch2cal(rtctime.get())
                            date =
                                string.format(
                                "%04d-%02d-%02d %02d:%02d:%02d",
                                tm["year"],
                                tm["mon"],
                                tm["day"],
                                tm["hour"],
                                tm["min"],
                                tm["sec"]
                            )
                            print(string.format("[init] - ntp sync with %s ok: %s UTC/GMT", server, date))
                            cfg.ntp.synced = true
                        end,
                        function(err)
                            print("failed! " .. err)
                            cfg.ntp.synced = false
                        end
                    )
                end
            end
        end
    )
end

-- ### main part
local cfg_file = "config"

-- compile config file
compile_lua(cfg_file)

-- load config from file
if run_lc(cfg_file) == false then
    print("[init] - Config file not found. Using default values.")
    cfg = {}
    cfg.wifi = {}
    cfg.wifi.mode = wifi.SOFTAP
    cfg.wifi.ssid = "CDC"
    cfg.wifi.pwd = ""
    cfg.wifi.auth = wifi.OPEN
    cfg.wifi.channel = 6
    cfg.wifi.hidden = false
    cfg.wifi.max = 4
    cfg.wifi.save = false

    cfg.hostname = "car"

    cfg.runnables = {}
    cfg.runnables.sources = {}

    cfg.ntp = {}
    cfg.ntp.server = false
end

cfg.runnables.active = {}
cfg.ntp.synced = false

-- build runnables
for _, item in ipairs(cfg.runnables.sources) do
    print("[init] - preparing " .. item)
    local status, error = pcall(compile_lua, item)
    if status == true then
        table.insert(cfg.runnables.active, item)
    else
        print("[init] - Error compiling " .. item .. ": " .. error)
    end
end

print(string.format("[init] - %u Bytes free", node.heap()))

stats = {}
stats.heap = node.heap()    -- history of heap values

-- setup general configuration
wifi.sta.sethostname(cfg.hostname)

-- Set-up Wifi AP
wifi.setmode(cfg.wifi.mode)

if cfg.wifi.mode == wifi.SOFTAP then
    print("[init] - setting up SoftAP...")
    wifi.ap.config(cfg.wifi)
    wifi.ap.setip(cfg.net)
    mdns.register(cfg.hostname, {description = "CDC rocks", service = "http", port = 80, location = "Earth"})

    wifi.eventmon.register(
        wifi.eventmon.AP_STACONNECTED,
        function(T)
            print("[init] - client connected (" .. T.MAC .. ")")
        end
    )

    wifi.eventmon.register(
        wifi.eventmon.AP_STADISCONNECTED,
        function(T)
            print("[init] - disconnected (" .. T.MAC .. ")")
        end
    )

    start_runnables()
elseif cfg.wifi.mode == wifi.STATION then
    print("[init] - Connecting to AP...")
    wifi.sta.config(cfg.wifi)
    wifi.sta.connect()
    wifi_monitor()
end
