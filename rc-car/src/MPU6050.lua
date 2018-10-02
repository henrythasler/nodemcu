MPU6050 = {} 
MPU6050.__index = MPU6050 

function MPU6050.new(address)
  local self = setmetatable({}, MPU6050)
  self.address = address
  return self
end

function MPU6050.init(self, pinSDA, pinSCL)
    local res = i2c.setup(0, pinSDA, pinSCL, i2c.SLOW)
    if res == i2c.SLOW then
        if self:read_reg(0x75) == self.address then
            self:write_reg(0x6B, 0x01)  -- PWR_MGMT_1: disable SLEEP and set CLKSEL to use PLL (x-Axis Gyro)
            return true
        end 
    end
    return false
end

function MPU6050.read_reg(self, register)
    i2c.start(0)
    i2c.address(0, self.address, i2c.TRANSMITTER)
    i2c.write(0, register)
    i2c.stop(0)
    i2c.start(0)
    i2c.address(0, self.address, i2c.RECEIVER)
    local c = i2c.read(0, 1)
    i2c.stop(0)
    return string.byte(c)
end

function MPU6050.write_reg(self, register, data)
    i2c.start(0)
    i2c.address(0, self.address, i2c.TRANSMITTER)
    i2c.write(0, register)
    i2c.write(0, data)
    i2c.stop(0)
end

function MPU6050.toNumber(self, msb, lsb)
    local val = msb * 0x100 + lsb
    return ((val >= 32768) and (val-65536) or val)
end

function MPU6050.getTemp(self)
    return self:toNumber(self:read_reg(0x41), self:read_reg(0x42)) / 340 + 36.53
end

sensor = MPU6050.new(0x68)
if sensor:init(2, 1) then 
    print("[sensor] - found MPU6050")
    print(string.format("[sensor] - Temperature=%i°C", sensor:getTemp()))
else 
    print("[sensor] - no sensor found") 
end

--[[
-- initialize i2c, set D2/GPIO4 as sda, set D1/GPIO5 as scl
i2c.setup(0, 2, 1, i2c.SLOW)

local PWR_MGMT_1 = 0x6B


-- user defined function: read from reg_addr content of dev_addr
function read_reg(device, address)
    i2c.start(0)
    i2c.address(0, device, i2c.TRANSMITTER)
    i2c.write(0, address)
    i2c.stop(0)
    i2c.start(0)
    i2c.address(0, device, i2c.RECEIVER)
    local c = i2c.read(0, 1)
    i2c.stop(0)
    return string.byte(c)
end

function write_reg(device, address, data)
    i2c.start(0)
    i2c.address(0, device, i2c.TRANSMITTER)
    i2c.write(0, address)
    i2c.write(0, data)
    i2c.stop(0)
end

-- MPU6050 properties, registers and value ranges
local g_earth = 9.80665
local MPU6050_ADDR = 0x68   -- i2c address
local ACCEL_FS_2G = 16384   -- scaling

-- register 
local ACCEL_XOUT_H = 0x3B
local ACCEL_XOUT_L = 0x3C

local TEMP_OUT_H = 0x41
local TEMP_OUT_L = 0x42

-- convert 2's complement (signed from unsigned) to number (from http://stackoverflow.com/questions/15191768/ddg#15191834)
local function toNumber(msb, lsb)
    local val = msb * 0x100 + lsb
    return ((val >= 32768) and (val-65536) or val)
end

-- ATTENTION: The device will come up in sleep mode upon power-up and needs to be woken up before use.
if read_reg(MPU6050_ADDR, 0x75) == MPU6050_ADDR then
    print(string.format("[MPU6050] - found MPU6050 at address 0x%X", MPU6050_ADDR))
    write_reg(MPU6050_ADDR, PWR_MGMT_1, 0x01)  -- disable SLEEP and set CLKSEL to use PLL (x-Axis Gyro)
    tmr.alarm (1, 4000, tmr.ALARM_AUTO, function ()
        local ACLNX_m_s2 = toNumber(read_reg(MPU6050_ADDR, ACCEL_XOUT_H), read_reg(MPU6050_ADDR, ACCEL_XOUT_L)) / ACCEL_FS_2G * g_earth
        local TEMP_OUT_degC = toNumber(read_reg(MPU6050_ADDR, TEMP_OUT_H), read_reg(MPU6050_ADDR, TEMP_OUT_L)) / 340 + 36.53
        print(string.format("[MPU6050] - MPU6050 - ACLNX=%.2f m/s^2  TEMP=%i", ACLNX_m_s2, TEMP_OUT_degC))
        print(string.format("[MPU6050] - %u Bytes free", node.heap()))
    end)
end

]]--