local function encode(payload, opcode)
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

local function decode(payload, mask)

end

return function(sck, request)
    local opcodes = {[0]="Continuation", [1]="Text", [2]="binary", [8]="Close", [9]="Ping", [10]="Pong"}

    -- callback upon completion of current response
    local function ws_sent(local_conn)
       -- print("[ws] - sent")
        --local_conn:close()
    end

    local function ws_receive(local_conn, data)
        local temp = {}
        for i = 1, #data do
            temp[#temp + 1] = string.format("%X ", string.byte(data, i))
        end
        print("[ws] - received: " .. table.concat(temp))
        print("Opcode: ".. opcodes[bit.band(string.byte(data, 1), 0x0f)])
        --local_conn:close()
    end

    local function ws_disconnect(local_conn)
        print("[ws] - close")
        tmr.unregister(2)
        maxThreads = maxThreads + 1
        --local_conn:close()
    end

    -- 250ms seems to be the minimal sending interval of the TCP module. Calling this timer more often results in burst transmission.
    -- Based on measurements. Couldn't find any hard evidence...
    tmr.alarm(
        2,
        250,
        tmr.ALARM_AUTO,
        function()
            local ax, ay, az = sensor:getAcceleration()
            local data = '{"ax":' .. ax .. ',"ay":' .. ay .. ',"az":' .. az .. "}"
            sck:send(encode(data, 0x01))
        end
    )

    -- (un)register websocket callbacks
    sck:on("sent", nil)
    sck:on("disconnection", ws_disconnect)
    sck:on("receive", ws_receive)

    local key = request:match("Sec%-WebSocket%-Key: ([A-Za-z0-9+/=]+)")
    local accept = crypto.toBase64(crypto.hash("sha1", key .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))

    -- delete unused callback function 
    on_sent = nil
    on_receive = nil

    dofile("webserver-header.lc")(
        sck,
        101,
        nil,
        false,
        {"Sec-WebSocket-Accept: " .. accept, "Upgrade: websocket", "Connection: Upgrade"}
    )
    return true
end
