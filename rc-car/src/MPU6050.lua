MPU6050 = {}
MPU6050.__index = MPU6050

function MPU6050.new(address)
    local self = setmetatable({}, MPU6050)
    self.address = address
    self.present = false
    return self
end

function MPU6050.init(self, pinSDA, pinSCL)
    local res = i2c.setup(0, pinSDA, pinSCL, i2c.SLOW)
    if res == i2c.SLOW then
        if self:read_reg(0x75) == self.address then
            self:write_reg(0x6B, 0x01) -- PWR_MGMT_1: disable SLEEP and set CLKSEL to use PLL (x-Axis Gyro)
            self:write_reg(0x1C, 0x10) -- ACCEL_CONFIG: AFS_SEL=2 (8g)
            self:write_reg(0x1a, 0x03) -- CONFIG: DLPF_CFG=3 (~40Hz)
            self:write_reg(0x1b, 0x08) -- GYRO_CONFIG: FS_SEL=1 (500°/s)
            self.present = true
        end
    end
    return self.present
end

function MPU6050.isPresent(self)
    return self.present
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

function MPU6050.read_burst(self, register, count)
    i2c.start(0)
    i2c.address(0, self.address, i2c.TRANSMITTER)
    i2c.write(0, register)
    i2c.stop(0)
    i2c.start(0)
    i2c.address(0, self.address, i2c.RECEIVER)
    local c = i2c.read(0, count)
    i2c.stop(0)
    return c
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
    return ((val >= 32768) and (val - 65536) or val)
end

function MPU6050.getTemp(self)
    -- register: TEMP_OUT_H=0x41; TEMP_OUT_L=0x42
    local data = self:read_burst(0x41, 2) -- read 2 consecutive bytes from sensor chip
    return self:toNumber(string.byte(data, 1), string.byte(data, 2)) / 340 + 36.53
end

-- return the acceleration in units of 1g
function MPU6050.getAcceleration(self)
    -- register: ACCEL_XOUT_H=0x3B
    -- scaling: 2g = 16384 LSB/g; 4g = 8192 LSB/g; 8g = 4096 LSB/g;
    local data = self:read_burst(0x3B, 6) -- read 6 consecutive bytes from sensor chip
    return self:toNumber(string.byte(data, 1), string.byte(data, 2)) / 4096, self:toNumber(
        string.byte(data, 3),
        string.byte(data, 4)
    ) / 4096, self:toNumber(string.byte(data, 5), string.byte(data, 6)) / 4096
end

function MPU6050.getGyroscope(self)
    -- register: GYRO_XOUT=0x43
    -- scaling: Full-Scale 500°/s
    local data = self:read_burst(0x43, 6) -- read 6 consecutive bytes from sensor chip
    local gx = self:toNumber(string.byte(data, 1), string.byte(data, 2)) / 65.5
    local gy = self:toNumber(string.byte(data, 3), string.byte(data, 4)) / 65.5
    local gz = self:toNumber(string.byte(data, 5), string.byte(data, 6)) / 65.5
    return gx, gy, gz
end

-- read all available data in one batch (3xAcceleration, 1xTemp, 3xGyroscope)
function MPU6050.readAll(self)
    local data = self:read_burst(0x3B, 14) -- read 14 consecutive bytes from sensor chip
    return self:toNumber(string.byte(data, 1), string.byte(data, 2)) / 4096, 
           self:toNumber(string.byte(data, 3), string.byte(data, 4)) / 4096, 
           self:toNumber(string.byte(data, 5), string.byte(data, 6)) / 4096,
           self:toNumber(string.byte(data, 7), string.byte(data, 8)) / 340 + 36.53,
           self:toNumber(string.byte(data, 9), string.byte(data, 10)) / 65.5,
           self:toNumber(string.byte(data, 11), string.byte(data, 12)) / 65.5,
           self:toNumber(string.byte(data, 13), string.byte(data, 14)) / 65.5
end

-- create global sensor object
sensor = MPU6050.new(0x68)

-- initialize sensor with pins 2=D2/GPIO4 as SDA and 1=D1/GPIO5 as SCL
tmr.alarm(
    4,
    2000,
    tmr.ALARM_AUTO,
    function()
        if not sensor:init(2, 1) then
            print("[sensor] - no sensor found")
        else
            tmr.unregister(4)
        end
    end
)
