
function connect (conn, data)
   local query_data

   conn:on ("receive",
      function (conn, req_data)
         query_data = get_http_req (req_data)
         print (query_data["METHOD"] .. " " .. " " .. query_data["User-Agent"])
--         conn:send('HTTP/1.1 200 OK\n\n'..'<!DOCTYPE HTML>\n<html>\n<head><meta  content="text/html; charset=utf-8">\n'..'<title>ESP8266 Blinker Thing</title></head>\n<body><h1>ESP8266 Blinker Thing!</h1>\n</body></html>\n')
          ok, json = pcall(cjson.encode, sensordata)
          if not ok then
            print("failed to encode!")
          end
         conn:send(json)
         -- Close the connection for the request
         conn:on("sent", function(conn) conn:close() end)
      end)
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

-- close existing server, if exists
if httpserver ~= nil then
  httpserver:close()
  httpserver = nil
end

-- Create the http server
httpserver = net.createServer (net.TCP, 10)

-- Server listening on port 80, call connect function if a request is received
httpserver:listen (80, connect)
print( "http server waiting for connections" )
