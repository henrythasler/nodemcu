return function (conn, code, fileExt, isGzipped, extraHeaders)
    local codes = {
        [101] = " Switching Protocols",
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
    hdr[#hdr + 1] = "HTTP/1.1 "
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
