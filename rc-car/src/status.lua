return function(sck, request)
    local majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info()
    local remaining, used, total = file.fsinfo()
    local _, reset_reason = node.bootreason()
    local total_allocated, estimated_used = node.egc.meminfo()
    local addr, netmask, gateway = (cfg.wifi.mode == wifi.STATION) and wifi.sta.getip() or wifi.ap.getip()
    local data = {
        timestamp = rtctime.get(),
        node = {
            majorVer = majorVer,
            minorVer = minorVer,
            devVer = devVer,
            chipid = chipid,
            flashid = flashid,
            flashsize = flashsize,
            flashmode = flashmode,
            flashspeed = flashspeed,
            reset_reason = reset_reason,
            cpufreq = node.getcpufreq(),
        },
        mem = {
            total_allocated = total_allocated, 
            estimated_used = estimated_used,
        },
        net = {
            hostname = (cfg.wifi.mode == wifi.STATION) and wifi.sta.gethostname() or wifi.ap.gethostname(),
            channel = wifi.getchannel(),
            address = addr,
            netmask = netmask,
            gateway = gateway,
            mac = (cfg.wifi.mode == wifi.STATION) and wifi.sta.getmac() or wifi.ap.getmac(),
            rssi = (cfg.wifi.mode == wifi.STATION) and wifi.sta.getrssi() or nil,
            ssid = (cfg.wifi.mode == wifi.STATION) and wifi.sta.getconfig() or wifi.ap.getconfig(),
        },
        fs = {
            remaining = remaining,
            used = used,
            total = total,
        },
        files = file.list(),
    }

    -- use as stream-json-encoder to chunk large content
    local encoder = sjson.encoder(data)

    -- callback upon completion of current response
    local function on_sent(local_conn)
        local chunk = encoder:read(256) -- send 256-Byte chunks
        if chunk then
            -- send chunk to client and wait for next callback
            local_conn:send(chunk)
        else
            -- all done; close socket and release semaphore when done
            local_conn:close()
            maxThreads = maxThreads + 1
        end
    end

    -- register callback
    sck:on("sent", on_sent)

    -- send http-header ("200 OK") with matching MIME-Type; on_sent is called upon completion
    dofile("webserver-header.lc")(sck, 200, "json", false)
end
