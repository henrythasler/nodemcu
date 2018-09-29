pl = nil;
sv=net.createServer(net.TCP, 10)
sv:listen(81,function(conn)
	conn:on("receive", function(conn, pl)
--		local _, count = pl:gsub('\n', '\n')
--		print('received', count, 'lines')
  local header = {}
	local x = 0
	if (sjson == nil) then
		sjson = cjson
	 end
	for line in string.gmatch(pl, '[^\n]+') do
		if x == 0 then
			print('Command: '..line)
			header = sjson.decode(line)
			if header.cmd == 'new' then
				file.open(header.file, "w+")
			elseif header.cmd == 'append' then --append
				file.open(header.file, "a+")
			elseif header.cmd == 'reset' then --restart
				conn:send("ok")
				conn:close()
				tmr.alarm (0, 500, tmr.ALARM_AUTO, function () node.restart() end)
			end
		else
			file.writeline(line)
		end
		x = x + 1
	end
	file.close(header.file)
	conn:send("ok")
	end)
end)
