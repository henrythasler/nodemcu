-- Compile additional files
local files = {
    "webserver-request.lua"
}
for i, f in ipairs(files) do
    if file.exists(f) then
        print("Compiling:", f)
        node.compile(f)
        file.remove(f)
        collectgarbage()
    end
end

files = nil
collectgarbage()

local function sendHeader(conn, code, fileExt, isGzipped, extraHeaders)
    local codes = {
        [200] = " OK",
        [301] = " Moved Permanently",
        [400] = " Bad Request",
        [404] = " Not Found",
        [429] = " Too Many Requests",
        [500] = " Internal Server Error"
    }
    local mime = {
        css = "text/css\r\n",
        gif = "image/gif\r\n",
        html = "text/html\r\n",
        ico = "image/x-icon\r\n",
        jpeg = "image/jpeg\r\n",
        jpg = "image/jpeg\r\n",
        js = "application/javascript\r\n",
        json = "application/json\r\n",
        png = "image/png\r\n",
        xml = "text/xml\r\n"
    }
    local hdr = {}
    hdr[#hdr + 1] = "HTTP/1.0 "
    hdr[#hdr + 1] = tostring(code)
    hdr[#hdr + 1] = codes[code] and codes[code] or " Internal Server Error"
    hdr[#hdr + 1] = "\r\nServer: CDC-Backend\r\nContent-Type: "
    hdr[#hdr + 1] = mime[fileExt] and mime[fileExt] or "text/plain\r\n"
    if isGzipped then
        hdr[#hdr + 1] = "Content-Encoding: gzip\r\n"
    end

    if (extraHeaders) then
        for i, extraHeader in ipairs(extraHeaders) do
            hdr[#hdr + 1] = extraHeader .. "\r\n"
        end
    end
   
    hdr[#hdr + 1] = "Connection: close\r\n\r\n"
    conn:send(table.concat(hdr))
end

serverBusy = false

local function on_receive(sck, data)
    local done = false
    local filesize = nil
    local request = nil
    local bytesRemaining = 0

    -- buffer configuration
    -- better set to the recommended chunk size for file.read() of 1024 bytes. Increase for better transmission rates but more memory usage
    local chunkSize = 1400

    local function on_sent(local_conn)
        if bytesRemaining > 0 then
            local fileHandle = file.open(request.uri.file)
            if fileHandle then
                fileHandle:seek("set", filesize - bytesRemaining)
                local bytesToRead = 0
                if bytesRemaining > chunkSize then
                    bytesToRead = chunkSize
                else
                    bytesToRead = bytesRemaining
                end
                local chunk = fileHandle:read(bytesToRead)
                local_conn:send(chunk)
                bytesRemaining = bytesRemaining - #chunk
                --print(request.uri.file .. ": Sent "..#chunk.. " bytes, " .. bytesRemaining .. " to go.")
                fileHandle:close()
            else
                print("[http] - File I/O error")
                done = true
            end
        else
            done = true
        end

        -- close connection when done
        if done then
            local_conn:close()
            serverBusy = false
        end
    end
    sck:on("sent", on_sent)

    if serverBusy then
        print("[http] - Server busy")
        sendHeader(sck, 429, nil, false, {"Retry-After: 5"})
        return
    end
    serverBusy = true

    request = dofile("webserver-request.lc")(data)
    print(request.method, request.resource, request.uri.file)

    for k, v in pairs(request.uri.args) do
        print(k, v)
    end

    local fileExists = false

    if not file.exists(request.uri.file) then
        if file.exists(request.uri.file .. ".gz") then
            print("gzip variant exists, serving that one")
            request.uri.file = request.uri.file .. ".gz"
            request.uri.isGzipped = true
            fileExists = true
        end
    else
        fileExists = true
    end

    if fileExists then
        if request.uri.isScript then
            print("running", request.uri.file)
            sendHeader(sck, 200, "json", false)
            sck:send(string.format('{"Temperature": %i}', sensor:getTemp()))
        else
            print(request.uri.file .. " found")
            filesize = file.list()[request.uri.file]
            bytesRemaining = filesize
            sendHeader(sck, 200, request.uri.ext, request.uri.isGzipped)
            --on_sent(sck)
        end
    else
        print(request.uri.file .. " not found")
        sck:send(
            "HTTP/1.0 404 Not Found\r\n\r\n<html><head><title>404 - Not Found</title></head><body><h1>404 - Not Found: " ..
                request.uri.file .. "</h1></body></html>\r\n"
        )
    end
end

function on_connect(conn)
    conn:on("receive", on_receive)
end

local httpserver = net.createServer(net.TCP, 30)
if httpserver then
    httpserver:listen(80, on_connect)
    print("[http] - waiting for connections")
else
    print("[http] - can't open socket")
end
