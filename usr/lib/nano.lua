local component = require("component")
local event = require("event")

-----------------------------------------

local function getModem()
    for address in component.list("modem") do
        local proxy = component.proxy(address)
        if proxy.isWireless() == true then
            return proxy
        end
    end
    error("wireless modem is not available")
end

-----------------------------------------

local lib = {}

local ok = false
lib.isOk = function()
    return ok
end

lib.raw_send = function(...)
    local modem = getModem()
    local port = math.random(1, 65535)
    local strength = modem.setStrength(2)
    local isOpen = modem.open(port)

    modem.broadcast(port, "nanomachines", "setResponsePort", port)
    local eventName = event.pull(4, "modem_message", modem.address, nil, port, nil, "nanomachines", "port", port)
    if not eventName then
        ok = false
        modem.setStrength(strength)
        if isOpen == true then
            modem.close(port)
        end
        return
    end
    modem.broadcast(port, "nanomachines", ...)

    modem.setStrength(strength)
    local data = table.pack(event.pull(4, "modem_message", modem.address, nil, port, nil, "nanomachines"))
    if isOpen == true then
        modem.close(port)
    end

    local returnData = {}
    for i = 7, #data do
        returnData[#returnData + 1] = data[i]
    end
    ok = true
    return table.unpack(returnData)
end

--------------------

lib.getInput = function(num)
    local _, _, out = lib.raw_send("getInput", num)
    return out
end

lib.setInput = function(num, state)
    lib.raw_send("setInput", num, state)
end

lib.getActiveEffects = function()
    local _, out = lib.raw_send("getActiveEffects")
    return out
end

lib.getMaxActiveInputs = function()
    local _, out = lib.raw_send("getMaxActiveInputs")
    return out
end

lib.getSafeActiveInputs = function()
    local _, out = lib.raw_send("getSafeActiveInputs")
    return out
end

lib.getTotalInputCount = function()
    local _, out = lib.raw_send("getTotalInputCount")
    return out
end

lib.getExperience = function()
    local _, out = lib.raw_send("getExperience")
    return out
end

lib.getName = function()
    local _, out = lib.raw_send("getName")
    return out
end

lib.getHunger = function()
    local _, out1, out2 = lib.raw_send("getHunger")
    return out1, out2
end

lib.getAge = function()
    local _, out = lib.raw_send("getAge")
    return out
end

lib.getHealth = function()
    local _, out = lib.raw_send("getHealth")
    return out
end

lib.getPowerState = function()
    local _, out1, out2 = lib.raw_send("getPowerState")
    return out1, out2
end

lib.saveConfiguration = function()
    local _, out1, out2 = lib.raw_send("saveConfiguration")
    return out1, out2
end

return lib