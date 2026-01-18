-- Monitors the reactor to keep control rods in an efficent spot
-- Also will disable the quantum quarry if the fuel drops below 25%

local component = require("component")
local sides = require("sides")

local reactor = component.br_reactor
local reactor_rs = component.proxy(component.get("5c8f"))
local quarry_rs = component.proxy(component.get("1efd"))
local gpu = component.gpu

local HEAT_UPPER_LIMIT = 1000
local HEAT_LOWER_LIMIT = 900
local QUARRY_DISABLE_LIMIT = 25
local QUARRY_ENABLE_LIMIT = 50

local direction = {
    UP = 1,
    DOWN = -1
}

local status = {
    DISABLE = 0,
    ENABLE = 1
}

-- Returns total heat value integer
local function checkHeat()
    return math.floor(reactor.getFuelTemperature())
end

-- Returns percent total fuel value
local function checkFuel()
    local total = reactor.getFuelAmountMax()
    local current = reactor.getFuelAmount()
    local remaining = math.floor((current / total) * 100)
    return remaining
end

-- Send a quick redstone signal
local function pulse(port, side)
    port.setOutput(side, 15)
    os.sleep(0.1)
    port.setOutput(side, 0)
end

-- Moves rods by specified amount
local function moveRods(vector)
    if vector == direction.UP then
        pulse(reactor_rs, sides.west)
    elseif vector == direction.DOWN then
        pulse(reactor_rs, sides.east)
    end

    local all = reactor.getControlRodsLevels()
    local newLevel = math.floor(all[1])
    print("MOVED -> ".. vector .." TO: ".. newLevel)
end

-- Inspect the redstone status on the computer itself
local function checkQuarryStatus()
    if quarry_rs.getOutput(sides.west) == 0 then
        return status.DISABLE
    end
    return status.ENABLE
end

-- Will enable or disable the quarry
local function toggleQuarry(nextState)
    if nextState == status.DISABLE then
        quarry_rs.setOutput(sides.top, 0)
        gpu.setForeground(0xFF0000)
        print("QUARRY DISABLED " .. os.date())
        gpu.setForeground(0xFFFFFF)
    elseif nextState == status.ENABLE then
        quarry_rs.setOutput(sides.top, 15)
        gpu.setForeground(0x00FF00)
        print("QUARRY ENABLED " .. os.date())
        gpu.setForeground(0xFFFFFF)
    end
end

-- Main loop
while true do

    if reactor.getActive() == true then

        -- Grab Current values
        local currentHeat = checkHeat()
        local currentFuel = checkFuel()
        local quarryStatus = checkQuarryStatus()

        -- Controlling the reactor
        if currentHeat > HEAT_UPPER_LIMIT then
            moveRods(direction.DOWN)
        elseif currentHeat < HEAT_LOWER_LIMIT then
            moveRods(direction.UP)
        end

        -- Disable the quarry if the fuel is less than 25% and enable when the fuel is back to 50% (dampen)
        if currentFuel < QUARRY_DISABLE_LIMIT then
            if quarryStatus == status.ENABLE then
                toggleQuarry(status.DISABLE)
            end
        elseif currentFuel > QUARRY_ENABLE_LIMIT then
            if quarryStatus == status.DISABLE then
                toggleQuarry(status.ENABLE)
            end
        end
    else
        gpu.setForeground(0xFF0000)
        print("REACTOR OFFLINE!")
        gpu.setForeground(0xFFFFFF)
    end

    os.sleep(5)

end
