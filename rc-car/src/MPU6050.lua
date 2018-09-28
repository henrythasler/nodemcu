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

-- sensor properties, registers and value ranges
local g_earth = 9.80665

local MPU6050_ADDR = 0x68   -- i2c address

local ACCEL_XOUT_H = 0x3B
local ACCEL_XOUT_L = 0x3C
local ACCEL_FS_2G = 16384   -- scaling

local TEMP_OUT_H = 0x41
local TEMP_OUT_L = 0x42

-- convert 2's complement (signed from unsigned) to number (from http://stackoverflow.com/questions/15191768/ddg#15191834)
local function toNumber(msb, lsb)
    local val = msb * 0x100 + lsb
    if val >= 32768 then val=val-65536 end
    return val
end

-- ATTENTION: The device will come up in sleep mode upon power-up and needs to be woken up before use.
if read_reg(MPU6050_ADDR, 0x75) == MPU6050_ADDR then
    print(string.format("found MPU6050 at address 0x%X", MPU6050_ADDR))
    write_reg(MPU6050_ADDR, PWR_MGMT_1, 0x01)  -- disable SLEEP and set CLKSEL to use PLL (x-Axis Gyro)

    tmr.alarm (0, 1000, tmr.ALARM_AUTO, function ()
        local ACLNX_m_s2 = toNumber(read_reg(MPU6050_ADDR, ACCEL_XOUT_H), read_reg(MPU6050_ADDR, ACCEL_XOUT_L)) / ACCEL_FS_2G * g_earth
        local TEMP_OUT_degC = toNumber(read_reg(MPU6050_ADDR, TEMP_OUT_H), read_reg(MPU6050_ADDR, TEMP_OUT_L)) / 340 + 36.53
        print(string.format("MPU6050 - ACLNX=%.2f m/s^2  TEMP=%.1f", ACLNX_m_s2, TEMP_OUT_degC))
    end)
end