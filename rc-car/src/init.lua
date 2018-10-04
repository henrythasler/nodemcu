local function compile_lua(filename)
    if file.exists(filename .. ".lua") then
        node.compile(filename .. ".lua")
        file.remove(filename .. ".lua")
        collectgarbage()
        return true
    else
        return false
    end
end

local function run_lc(filename)
    if file.exists(filename .. ".lc") then
        dofile(filename .. ".lc")
        return true
    else
        print("[init] - " .. filename .. ".lc not found.")
        return false
    end
end

local function start_runnables()
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

local function wifi_monitor(config)
    local connected = false
    local retry = 0
    tmr.alarm(
        0,
        2000,
        tmr.ALARM_AUTO,
        function()
            stats.heap = (stats.heap + node.heap())/2

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
                if cfg.ntp.server and (cfg.ntp.synced == false) and not cfg.ntp.inProgress then
                    cfg.ntp.inProgress = true
                    sntp.sync(
                        cfg.ntp.server,
                        function(sec, usec, server)
                            local tm = rtctime.epoch2cal(rtctime.get())
                            local date =
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
                            cfg.ntp.inProgress = false
                        end,
                        function(err)
                            print("[init] - ntp sync failed")
                            cfg.ntp.synced = false
                            cfg.ntp.inProgress = false
                        end
                    )
                end
            end
        end
    )
end

-- ### main part
-- compile config file
compile_lua("config")

-- compile all user-scripts
local l = file.list("^usr/.+(%.lua)$")
for k, v in pairs(l) do
    if file.exists(k) then
        print("Compiling:", k)
        node.compile(k)
        --file.remove(k)    -- do not remove file, might want to download into browser
        collectgarbage()
    end
end

-- load config from file
if run_lc("config") == false then
    print("[init] - Config file not found. Using default values.")
    cfg = {}
    cfg.wifi = {}
    cfg.wifi.mode = wifi.SOFTAP
    cfg.wifi.ssid = "CDC"
    cfg.wifi.pwd = "00000000"
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

    cfg.net = {}
    cfg.net.ip = "192.168.1.1"
    cfg.net.netmask="255.255.255.0"
    cfg.net.gateway="192.168.1.1"
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
