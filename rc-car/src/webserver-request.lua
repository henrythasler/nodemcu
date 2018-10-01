local function hex_to_char(x)
 return string.char(tonumber(x, 16))
end

local function uri_decode(input)
 return input:gsub("%+", " "):gsub("%%(%x%x)", hex_to_char)
end

local function parseArgs(args)
  local r = {}
  local i = 1
  if args == nil or args == "" then return r end
  for arg in string.gmatch(args, "([^&]+)") do
     local name, value = string.match(arg, "(.*)=(.*)")
     if name ~= nil then r[name] = uri_decode(value) end
     i = i + 1
  end
  return r
end

local function parseFormData(body)
  local data = {}
  --print("Parsing Form Data")
  for kv in body.gmatch(body, "%s*&?([^=]+=[^&]+)") do
     local key, value = string.match(kv, "(.*)=(.*)")
     --print("Parsed: " .. key .. " => " .. value)
     data[key] = uri_decode(value)
  end
  return data
end

local function getRequestData(payload)
  local requestData
  return function ()
     --print("Getting Request Data")
     -- for backward compatibility before v2.1
     if (sjson == nil) then
        sjson = cjson
     end
     if requestData then
        return requestData
     else
        --print("payload = [" .. payload .. "]")
        local mimeType = string.match(payload, "Content%-Type: ([%w/-]+)")
        local bodyStart = payload:find("\r\n\r\n", 1, true)
        local body = payload:sub(bodyStart, #payload)
        payload = nil
        collectgarbage()
        --print("mimeType = [" .. mimeType .. "]")
        --print("bodyStart = [" .. bodyStart .. "]")
        --print("body = [" .. body .. "]")
        if mimeType == "application/json" then
           --print("JSON: " .. body)
           requestData = sjson.decode(body)
        elseif mimeType == "application/x-www-form-urlencoded" then
           requestData = parseFormData(body)
        else
           requestData = {}
        end
        return requestData
     end
  end
end




local function parseUri(uri)
  local r = {}
  local filename
  local ext
  local fullExt = {}

  if uri == nil then return r end
  if uri == "/" then uri = "/index.html" end
  local questionMarkPos, b, c, d, e, f = uri:find("?")
  if questionMarkPos == nil then
     r.file = uri:sub(1, questionMarkPos)
     r.args = {}
  else
     r.file = uri:sub(1, questionMarkPos - 1)
     r.args = parseArgs(uri:sub(questionMarkPos+1, #uri))
  end
  filename = r.file
  while filename:match("%.") do
     filename,ext = filename:match("(.+)%.(.+)")
     table.insert(fullExt,1,ext)
  end
  if #fullExt > 1 and fullExt[#fullExt] == 'gz' then
     r.ext = fullExt[#fullExt-1]
     r.isGzipped = true
  elseif #fullExt >= 1 then
     r.ext = fullExt[#fullExt]
  end
  r.isScript = r.ext == "lua" or r.ext == "lc"
  r.file = string.sub(r.file, 2, -1)
  return r
end


--[[
  returns a table with the following properties:
      method (string)   : Request method (e.g. "GET") (https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods)
      resource (string) : 
      uri (table)       :
          file          :
          args          : Key-Value pairs of url arguments and other stuff
          ext           :
          isGzipped     :
          isScript      :
      getRequestData    : table with decoded (JSON or FORM) data
]]--
return function (request)
  --print("Request: \n", request)
  local e = request:find("\r\n", 1, true)
  if not e then return nil end
  local line = request:sub(1, e - 1)
  local r = {}
  local _, i
  _, i, r.method, r.resource = line:find("^([A-Z]+) (.-) HTTP/[1-9]+.[0-9]+$")
  if not (r.method and r.resource) then
     print("invalid request: ")
     print(request)
     return nil
  end

  local httpMethods = {GET=true, HEAD=true, POST=true, PUT=true, DELETE=true, TRACE=true, OPTIONS=true, CONNECT=true, PATCH=true}

  r.methodIsValid = httpMethods[r.method]
  r.uri = parseUri(r.resource)
  r.getRequestData = getRequestData(request)
  return r
end