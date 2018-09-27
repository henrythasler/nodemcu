function connect(conn, data)
  local header

  local function onReceive(conn, payload)
    header = get_http_req(payload)
    print (header["METHOD"] .. " " .. " " .. (header["REQUEST"] and header["REQUEST"] or ""))

    local content = {}
    content[#content+1] = 'HTTP/1.1 200 OK\n\n'
    content[#content+1] = '<!DOCTYPE HTML>\n<html>\n<head><meta  content="text/html; charset=utf-8">\n'
    content[#content+1] = '<title>CDC Rocks!</title></head>\n'
    content[#content+1] = '<body>'
    content[#content+1] = '<h1>CDC Rocks!</h1>\n'
    content[#content+1] = '<h2>Memory in use: '..collectgarbage("count")..'KB</h2>\n'
    content[#content+1] = '</body></html>\n'
--      local content = "HTTP/1.1 200 OK\n\n'..'<!DOCTYPE HTML>\n<html>\n<head><meta  content="text/html; charset=utf-8">\n'..'<title>CDC Rocks!</title></head>\n<body><h1>CDC Rocks!</h1>\n</body></html>\n"

    conn:send(table.concat(content))
  end

  local function onSent(conn)
    conn:close()
  end

  conn:on("receive", onReceive)
  conn:on("sent", onSent)
  conn:on("disconnection", onDisconnect)

end

-- String trim left and right
function trim (s)
  return (s:gsub ("^%s*(.-)%s*$", "%1"))
end

-- Build and return a table of the http request data
function get_http_req (instr)
   local t = {}
   local first = nil
   local key, v, strt_ndx, end_ndx

   for str in string.gmatch (instr, "([^\n]+)") do
      -- First line in the method and path
      if (first == nil) then
         first = 1
         strt_ndx, end_ndx = string.find (str, "([^ ]+)")
         v = trim (string.sub (str, end_ndx + 2))
         key = trim (string.sub (str, strt_ndx, end_ndx))
         t["METHOD"] = key
         t["REQUEST"] = v
      else -- Process and reamaining ":" fields
         strt_ndx, end_ndx = string.find (str, "([^:]+)")
         if (end_ndx ~= nil) then
            v = trim (string.sub (str, end_ndx + 2))
            key = trim (string.sub (str, strt_ndx, end_ndx))
            t[key] = v
         end
      end
   end

   return t
end


-- Create the http server
httpserver = net.createServer (net.TCP, 10)

-- Server listening on port 80, call connect function if a request is received
httpserver:listen (80, connect)
print( "http server waiting for connections" )
