pl = nil;
sv=net.createServer(net.TCP, 10)
    sv:listen(80,function(conn)
		conn:on("receive", function(conn, pl)
		payload = pl;
		print(pl.."\n")

    dofile("status.lua")
    tmr.delay(250)
    file.open("status.html", "r")
    conn:send(file.read())
		file.close("status.html")
		conn:close()
		collectgarbage()
		end)
end)
