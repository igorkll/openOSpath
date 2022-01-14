local component = require("component")
local event = require("event")
local su = require("superUtiles")
local computer = require("computer")

local realport = 488

local function openPorts()
    for address in component.list("modem") do
        local modem = component.proxy(address)
        modem.open(realport)
    end
end
openPorts()
event.timer(4, openPorts, math.huge)

--------------------------------------------------

local messagebuffer = {}
local life = {}

local function raw_send(...)
    for address in component.list("modem") do
        local modem = component.proxy(address)
        local strength
        if modem.isWireless() then
            strength = modem.setStrength(math.huge)
        end
        modem.broadcast(realport, ...)
        if strength then
            modem.setStrength(strength)
        end
    end
    for address in component.list("tunnel") do
        local tunnel = component.proxy(address)
        tunnel.send(...)
    end
end

local function cleanBuffer()
    for key, value in pairs(life) do
        if computer.uptime() - value > 8 then
            messagebuffer[key] = nil
            life[key] = nil
        end
    end
end
event.timer(1, cleanBuffer, math.huge)

local function addcode(code)
    local index = su.generateRandomID()
    messagebuffer[index] = code or su.generateRandomID()
    life[index] = computer.uptime()
    return messagebuffer[index]
end

--------------------------------------------------

local function listen(_, this, _, port, _, messagetype, code, ...)
    if su.inTable(messagebuffer, code) or messagetype ~= "bigchat" or (port ~= realport and port ~= 0) or type(code) ~= "string" then
        return
    end
    addcode(code)
    raw_send("bigchat", code, ...)
    event.push("big_chat", ...)
end
event.listen("modem_message", listen)

--------------------------------------------------

local lib = {}

lib.send = function(...)
    raw_send("bigchat", addcode(), ...)
end

return lib