function compile_lua(filename)
  if file.open(filename .. ".lua") then
    file.close()
    node.compile(filename .. ".lua")
    file.remove(filename .. ".lua")
    return true
  else
    return false
  end
end

function run_lc(filename)
  if file.open( filename .. ".lc" ) then
    file.close()
    dofile( filename .. ".lc" )
    return true
  else
    print("[init-lua] - " .. filename .. ".lc not found." )
    return false
  end
end

function run_lua(filename)
  if file.open( filename .. ".lua" ) then
    file.close()
    dofile( filename .. ".lua" )
    return true
  else
    print("[init-lua] - " .. filename .. ".lua not found." )
    return false
  end
end


-- ### main part
local cfg_file = "config"

-- compile config file
compile_lua(cfg_file)

-- load config from file
if run_lc(cfg_file) == false then
  print("[init-lua] - Config file not found. Using default values." )
  cfg={}
  cfg.wifi={}
  cfg.wifi.ssid="home"
  cfg.wifi.pwd="00000000"
  cfg.wifi.save=true
  cfg.hostname = "node01"
  cfg.runnables = {}
  cfg.runnables.sources = {}
  cfg.ntp = {}
  cfg.ntp.server = false
end

cfg.runnables.active = {}
cfg.ntp.synced = false

for _, item in ipairs(cfg.runnables.sources) do
  print("[init-lua] - preparing "..item)
  local status, error = pcall(compile_lua, item)
  if status == true then
    table.insert(cfg.runnables.active, item)
  else
    print('[init-lua] - Error compiling '..item..": "..error)
  end
end

-- setup general configuration
wifi.sta.sethostname( cfg.hostname )

-- Set-up Wifi AP
wifi.setmode( wifi.SOFTAP )
wifi.sta.config( cfg.wifi )
wifi.sta.connect()

-- start runnables
for _, item in ipairs(cfg.runnables.active) do
  if pcall(run_lc, item) then
    print("[init-lua] - starting "..item)
  else
    print('[init-lua] - Error running '..item)
  end
end

