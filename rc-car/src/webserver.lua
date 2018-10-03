-- Compile additional modules
local files = {
    "webserver-request.lua",
    "webserver-header.lua"
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
    

    -- allow only one request to be processed
    if serverBusy then
        print("[http] - Server busy")
        sck:on("sent", on_sent)
        dofile("webserver-header.lc")(sck, 429, nil, false, {"Retry-After: 5"})
        return
    end
    serverBusy = true

    request = dofile("webserver-request.lc")(data)
    print(request.method, request.resource, request.uri.file)

    for k, v in pairs(request.uri.args) do print(k, v) end

    local fileExists = false

    -- check for gzipped variant
    if not file.exists(request.uri.file) then
        if file.exists(request.uri.file .. ".gz") then
            --print("gzip variant exists, serving that one")
            request.uri.file = request.uri.file .. ".gz"
            request.uri.isGzipped = true
            fileExists = true
        end
    else
        fileExists = true
    end

    if fileExists then
        if request.uri.isScript then    -- let script handle the request
            print("running", request.uri.file)
            dofile(request.uri.file)(sck, request)
            --sendHeader(sck, 200, "json", false)
            --sck:send(string.format('{"Temperature": %i}', sensor:getTemp()))
        else -- regular file serving
            print(request.uri.file .. " found")
            filesize = file.list()[request.uri.file]
            bytesRemaining = filesize
            sck:on("sent", on_sent)
            dofile("webserver-header.lc")(sck, 200, request.uri.ext, request.uri.isGzipped)
            --on_sent(sck)
        end
    else
        print(request.uri.file .. " not found")
        sck:on("sent", on_sent)
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
