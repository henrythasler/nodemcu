local function encode(opcode, payload)
    local len = #payload
    local frame = {}
    frame[#frame + 1] =
        string.char(bit.bor(0x80, opcode), bit.bor((len < 126) and len or ((len < 0x10000) and 126 or 127)))
    if len >= 0x10000 then
        frame[#frame + 1] =
            string.char(
            0,
            0,
            0,
            0, -- 32 bit length is plenty, assume zero for rest
            bit.band(bit.rshift(len, 24), 0xff),
            bit.band(bit.rshift(len, 16), 0xff),
            bit.band(bit.rshift(len, 8), 0xff),
            bit.band(len, 0xff)
        )
    elseif len >= 126 then
        frame[#frame + 1] = string.char(bit.band(bit.rshift(len, 8), 0xff), bit.band(len, 0xff))
    end
    frame[#frame + 1] = payload
    return table.concat(frame)
end

return function(sck, request)
    local opcodes = {[0] = "Continuation", [1] = "Text", [2] = "binary", [8] = "Close", [9] = "Ping", [10] = "Pong"}
    local closingHandshake = false
    local statusCode = nil
    local txBufferContent = 0 -- keep track of transmit buffer content so we close the connection only AFTER everything was sent.

    local function sendSensorData(local_conn)
        if sensor:isPresent() then
            gpio.write(0, 1 - gpio.read(0)) -- toggle LED to indicate websocket-traffic
            local ax, ay, az = sensor:getAcceleration()
            local gx, gy, gz = sensor:getGyroscope()
            local data = {
                utc = rtctime.get(),
                timestamp = tmr.now(),
                temp = sensor:getTemp(),
                ax = ax,
                ay = ay,
                az = az,
                gx = gx,
                gy = gy,
                gz = gz
            }
            local_conn:send(encode(0x01, sjson.encode(data))) -- send as "Text" (0x01)
            txBufferContent = txBufferContent + 1
        end
    end

    -- callback upon completion of current response
    local function ws_sent(local_conn)
        txBufferContent = (txBufferContent > 0) and (txBufferContent - 1) or 0
        if closingHandshake then
            if txBufferContent == 0 then
                print("[ws] - closing")
                local_conn:close()
                maxThreads = maxThreads + 1
                gpio.write(0, 0) -- turn LED on
            end
        elseif txBufferContent == 0 then
            sendSensorData(local_conn)
        end
    end

    local function ws_receive(local_conn, data)
        local temp = {}
        local payload = nil

        for i = 1, #data do
            temp[#temp + 1] = string.format("%X ", string.byte(data, i))
        end
        print("[ws] - received: " .. table.concat(temp))
        local opcode = bit.band(string.byte(data, 1), 0x0f)
        print("[ws] - Opcode: " .. opcodes[opcode])

        local payloadLen = bit.band(string.byte(data, 2), 0x0f)
        if payloadLen == 126 then
            payloadLen = string.byte(data, 3) * 256 + string.byte(data, 4)
        elseif payloadLen == 127 then
            payloadLen = 0x10000 -- FIXME: needs implementation
        end

        print("[ws] - payloadLen=", payloadLen)

        -- connection is about to be closed (either client or server initiated)
        if opcode == 0x08 then
            if closingHandshake then
                print("[ws] - closingHandshake done - close")
                local_conn:close()
            else
                closingHandshake = true
                print("[ws] - closingHandshake return")
                --statusCode = 1001
                local_conn:send(
                    encode(0x08, "")
                    --string.char(bit.band(bit.rshift(statusCode, 8), 0xff), bit.band(statusCode, 0xff)))
                )
                txBufferContent = txBufferContent + 1
            end
        end
    end

    -- client closed the connection
    local function ws_disconnect(local_conn)
        print("[ws] - closed")
        maxThreads = maxThreads + 1
        gpio.write(0, 0) -- turn LED on
    end

    -- (un)register websocket callbacks
    sck:on("sent", ws_sent)
    sck:on("disconnection", ws_disconnect)
    sck:on("receive", ws_receive)

    -- compute response challenge as per rfc6455#section-1.3
    local key = request:match("Sec%-WebSocket%-Key: ([A-Za-z0-9+/=]+)")
    local accept = crypto.toBase64(crypto.hash("sha1", key .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))

    -- delete unused webserver callback functions
    on_sent = nil
    on_receive = nil

    dofile("webserver-header.lc")(
        sck,
        101,
        nil,
        false,
        {"Sec-WebSocket-Accept: " .. accept, "Upgrade: websocket", "Connection: Upgrade"}
    )
    print("[ws] - open")
    txBufferContent = txBufferContent + 1
    return true
end
