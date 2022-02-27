local component = require("component")
local event = require("event")
local serialization = require("serialization")
local su = require("superUtiles")
local computer = require("computer")

-------------------------------------------

local noAddress
local function raw_send(devices, name, code, data, obj, isResend, port)
    local noAddress2 = noAddress
    noAddress = nil
    for i = 1, #devices do
        local device = devices[i]
        if isResend then
            if device["resend"] == nil then
                if not obj.resend then
                    goto skip
                end
            elseif device["resend"] == false then
                goto skip
            end
        end
        local proxy = component.proxy(device[1])
        if proxy.type == "modem" then
            if isResend and proxy.address == noAddress2 and device[2] == port and (not proxy.isWireless() or device[3] == 0) then
                goto skip
            end
            local strength = device[3]
            local oldStrength
            if proxy.isWireless() then
                if strength then
                    oldStrength = proxy.getStrength()
                    proxy.setStrength(strength)
                end
            end

            proxy.broadcast(device[2], "network", name, code, data)

            if oldStrength then proxy.setStrength(oldStrength) end
        elseif proxy.type == "tunnel" then
            if not isResend or proxy.address ~= noAddress2 then
                proxy.send("network", name, code, data)
            end
        else
            error("unsupported device")
        end
        ::skip::
    end
end

local function isType(data, target)
    return type(data) == target
end

-------------------------------------------

local lib = {}

lib.networks = {}

function lib.create(devices, name, resend)
    checkArg(1, devices, "table")
    checkArg(2, name, "string")
    local obj = {}
    obj.devices = devices
    obj.name = name
    obj.resend = resend
    obj.renil = true
    obj.listens = {}
    obj.timers = {}

    --------------------------------------------------

    for i = 1, #obj.devices do
        local device = obj.devices[i]
        local proxy = component.proxy(device[1])
        if proxy.type == "modem" then
            device.isOpen = proxy.open(device[2])
        end
    end

    --------------------------------------------------

    local messagebuffer = {}
    local life = {}

    local function cleanBuffer()
        for key, value in pairs(life) do
            if computer.uptime() - value > 16 then
                messagebuffer[key] = nil
                life[key] = nil
            end
        end
    end
    obj.timers[#obj.timers + 1] = event.timer(1, cleanBuffer, math.huge)

    local function addcode(code)
        local index = su.generateRandomID()
        messagebuffer[index] = code or su.generateRandomID()
        life[index] = computer.uptime()
        return messagebuffer[index]
    end

    local function listen(_, this, _, port, _, messagetype, name, code, data)
        if not isType(messagetype, "string") or not isType(name, "string") or not isType(code, "string") then return end
        if su.inTable(messagebuffer, code) or name ~= obj.name then return end
        local ok = false
        local device
        for i = 1, #obj.devices do
            device = obj.devices[i]
            if device[1] == this and (port == 0 or device[2] == port) then
                ok = true
                break
            end
        end
        if not ok then return end
        addcode(code)
        local function resendPack()
            noAddress = this
            raw_send(obj.devices, obj.name, code, data, obj, true, port)
        end
        if device["resend"] == nil then
            if obj.resend then
                resendPack()
            end
        elseif device["resend"] == true then
            resendPack()
        end
        local out = serialization.unserialize(data)
        event.push("network_message", obj.name, table.unpack(out))
    end
    event.listen("modem_message", listen)
    obj.listens[#obj.listens + 1] = {"modem_message", listen}

    --------------------------------------------------

    function obj.send(...)
        local tbl = {...}
        local tbl2 = {}
        if obj.renil then
            local num = 0
            for i, data in pairs(tbl) do
                local raz = i - num
                num = i
                if raz > 1 then
                    raz = raz - 1
                    for i = 1, raz do
                        table.insert(tbl2, false)
                    end
                end
                table.insert(tbl2, data)
            end
        else
            tbl2 = tbl
        end
        local data = serialization.serialize(tbl2)
        raw_send(obj.devices, obj.name, addcode(), data, obj)
    end

    lib.networks[#lib.networks + 1] = obj
    local thisIndex = #lib.networks

    function obj.kill()
        for i = 1, #obj.timers do event.cancel(obj.timers[i]) end
        for i = 1, #obj.listens do event.ignore(table.unpack(obj.listens[i])) end
        for i = 1, #obj.devices do
            local device = obj.devices[i]
            if device["isOpen"] then
                component.proxy(device[1]).close(device[2])
            end
        end
        table.remove(lib.networks, thisIndex)
    end

    return obj
end

function lib.getDevices(tunnels, modems, wiredModems, wirelessModems, modemsPort, modemsStrength)
    if not modemsPort then modemsPort = 88 end
    if not modemsStrength then modemsStrength = math.huge end

    ------------------------------------------------------

    local devices = {}

    if tunnels then
        for address in component.list("tunnel") do
            devices[#devices + 1] = {address}
        end
    end
    if wiredModems then
        for address in component.list("modem") do
            if component.invoke(address, "isWired") and not component.invoke(address, "isWireless") then
                devices[#devices + 1] = {address, modemsPort, modemsStrength}
            end
        end
    end
    if wirelessModems then
        for address in component.list("modem") do
            if not component.invoke(address, "isWired") and component.invoke(address, "isWireless") then
                devices[#devices + 1] = {address, modemsPort, modemsStrength}
            end
        end
    end
    if modems then
        for address in component.list("modem") do
            devices[#devices + 1] = {address, modemsPort, modemsStrength}
        end
    end

    return devices
end

function lib.getNetwork(name)
    for i = 1, #lib.networks do
        if lib.networks[i].name == name then
            return lib.networks[i]
        end
    end
end

return lib