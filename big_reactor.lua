-- Monitors the reactor to keep control rods in an efficent spot
-- Also will disable the quantum quarry if the fuel drops below 25%

local component = require("component")
local colors = require("colors")
local sides = require("sides")

local reactor = component.br_reactor
local rs = component.redstone
local gpu = component.gpu

local direction = {
    UP = -5,
    DOWN = 5
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

-- Moves rods by specified amount
local function moveRods(vector)
    local level = math.floor(reactor.getControlRodLevel(1)) -- Pick any rod because they should all be synchonized
    local newLevel = math.floor(level + vector)
    reactor.setAllControlRodLevels(newLevel)
    print("MOVE ALL -> FROM: ".. vector .."TO: ".. newLevel)
end

-- Inspect the redstone status on the computer itself
local function checkQuarryStatus()
    if rs.getOutput(sides.west) == 0 then
        return status.DISABLE
    end
    return status.ENABLE
end

-- Will enable or disable the quarry
local function toggleQuarry(nextState)
    if nextState == status.DISABLE then
        rs.setOutput(sides.west, 0)
        gpu.setForeground(colors.red)
        print("QUARRY DISABLED " .. os.date())
        gpu.setForeground(colors.white)
    elseif nextState == status.ENABLE then
        rs.setOutput(sides.west, 15)
        gpu.setForeground(colors.green)
        print("QUARRY ENABLED " .. os.date())
        gpu.setForeground(colors.white)
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
        if currentHeat > 1000 then
            moveRods(direction.DOWN)
        elseif currentHeat < 900 then
            moveRods(direction.UP)
        end

        -- Disable the quarry if the fuel is less than 25% and enable when the fuel is back to 50% (dampen)
        if currentFuel < 25 then
            if quarryStatus == status.ENABLE then
                toggleQuarry(status.DISABLE)
            end
        elseif currentFuel > 50 then
            if quarryStatus == status.DISABLE then
                toggleQuarry(status.ENABLE)
            end
        end
    else
        gpu.setForeground(colors.red)
        print("REACTOR OFFLINE!")
        gpu.setForeground(colors.white)
    end

    os.sleep(5)

end
