pl = nil;
sv=net.createServer(net.TCP, 10)
  sv:listen(80,function(conn)
		conn:on("receive", function(conn, pl)

		local _, count = pl:gsub('\n', '\n')
		print('received', count, 'lines')

		local x = 0
		for line in string.gmatch(pl, '[^\n]+') do
			if x == 0 then 
			  print('Command: '..line)
			 	if line == 'NEW' then 
					file.open('temperature.lua', "w+")
			 	elseif line == 'APP' then --append 
				 	file.open('temperature.lua', "a+")
			 	elseif line == 'RES' then --restart
					conn:send("ok")
				  conn:close()
					tmr.delay(250)
					node.restart()
				end
			else 
				file.writeline(line)
			end
			x = x + 1
		end
		file.close('temperature.lua')
--		print(pl)

--    dofile("status.lua")
--    tmr.delay(250)
--    file.open("status.html", "r")
--    conn:send(file.read())
--		file.close("status.html")
		conn:send("ok")
		conn:close()
		collectgarbage()
		end)
end)
