local function encode(payload, opcode)
    opcode = opcode or 2
    assert(type(opcode) == "number", "opcode must be number")
    assert(type(payload) == "string", "payload must be string")
    local len = #payload
    local head = string.char(
      bit.bor(0x80, opcode),
      bit.bor(len < 126 and len or len < 0x10000 and 126 or 127)
    )
    if len >= 0x10000 then
      head = head .. string.char(
      0,0,0,0, -- 32 bit length is plenty, assume zero for rest
      bit.band(bit.rshift(len, 24), 0xff),
      bit.band(bit.rshift(len, 16), 0xff),
      bit.band(bit.rshift(len, 8), 0xff),
      bit.band(len, 0xff)
    )
    elseif len >= 126 then
      head = head .. string.char(bit.band(bit.rshift(len, 8), 0xff), bit.band(len, 0xff))
    end
    return head .. payload
  end

return function(sck, request)
    -- callback upon completion of current response
    local function on_sent(local_conn)
        print("[ws] - sent")
        --local_conn:close()
    end


    tmr.alarm(
        2,
        250,
        tmr.ALARM_AUTO,
        function()
            local ax, ay, az = sensor:getAcceleration()
            local data = '{"ax":'..ax..',"ay":'..ay..',"az":'..az..'}'
            sck:send(encode(data, 0x01))
        end)

    local function on_disconnect(local_conn)
        print("[ws] - close")
        tmr.unregister(2)
        maxThreads = maxThreads + 1
        --local_conn:close()
    end
    

    -- register callback
    --sck:on("sent", on_sent)
    sck:on("disconnection", on_disconnect)
    
    local key = request:match("Sec%-WebSocket%-Key: ([A-Za-z0-9+/=]+)")
    local accept = crypto.toBase64(crypto.hash("sha1", key.."258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))

    dofile("webserver-header.lc")(sck, 101, nil, false, {"Sec-WebSocket-Accept: "..accept, "Upgrade: websocket", "Connection: Upgrade"})
    return true
end
