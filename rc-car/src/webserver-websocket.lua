return function(sck, request)
    -- callback upon completion of current response
    local function on_sent(local_conn)
        print("[ws] - sent")
        --local_conn:close()
    end

    -- register callback
    sck:on("sent", on_sent)
    
    local key = request:match("Sec%-WebSocket%-Key: ([A-Za-z0-9+/=]+)")
    local accept = crypto.toBase64(crypto.hash("sha1", key.."258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))

    dofile("webserver-header.lc")(sck, 101, nil, false, {"Sec-WebSocket-Accept: "..accept, "Upgrade: websocket", "Connection: Upgrade"})
    return true
end
