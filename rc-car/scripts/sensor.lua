return function(sck, request)
    local ax, ay, az = sensor:getAcceleration()
    local gx, gy, gz = sensor:getGyroscope()
    -- this is the content of our response
    local data = {
        timestamp = rtctime.get(),
        temp = sensor and sensor:getTemp() or -40,
        ax = ax,
        ay = ay,
        az = az,
        gx = gx,
        gy = gy,
        gz = gz,
        avg_heap = stats.heap
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
