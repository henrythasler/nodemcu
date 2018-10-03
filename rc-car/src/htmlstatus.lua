return function(sck, request)
    -- This is actually bad practice: 
    -- By repeatedly calling sck:send() the content is just queued for transmission and not sent to the client
    -- Sending is initiated AFTER this function returns 
    -- So this is an easy way to quickly fill up your RAM and cause panic.

    dofile("webserver-header.lc")(sck, 200, "html", false)
    sck:send("<html><body bgcolor='#E6E6E6'><h1>System Info </h1><p>IP: ")
    sck:send(wifi.sta.getip() .. "</p><p>MAC: " .. wifi.sta.getmac())
    local majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info()
    sck:send(
        "<BR>NodeMCU: " ..
            majorVer .. "." .. minorVer .. "." .. devVer .. "<BR>Flashsize: " .. flashsize .. "<BR>ChipID: " .. chipid
    )
    sck:send("<BR>FlashID: " .. flashid .. "<BR>" .. "Flashmode: " .. flashmode .. "<BR>Heap: " .. node.heap())

    local r, u, t = file.fsinfo()
    sck:send(
        "<p>&nbsp;&nbsp;&nbsp;&nbsp;File System <BR><BR>Total Memory : " ..
            t .. " <BR>bytes\r\nUsed  : " .. u .. " <BR>bytes\r\nRemain: " .. r .. " bytes\r\n"
    )
    sck:send("<BR><BR>&nbsp;&nbsp;&nbsp;&nbsp;Files in memory<br><BR><table cellpadding ='2'>")
    local l = file.list()
    for k, v in pairs(l) do
        sck:send("<tr><td><B>" .. k .. "</td><td>" .. v .. " bytes</td></tr>")
    end
    sck:send("</table><BR><BR>&nbsp;&nbsp;&nbsp;&nbsp;End of info</html>")

    -- callback upon completion of current response
    local function on_sent(local_conn)
        local_conn:close()
        maxThreads = maxThreads + 1
    end

    -- register callback
    sck:on("sent", on_sent)
end
