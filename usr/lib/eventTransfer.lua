local thread = require("thread")
local bigchat = require("bigchat")
local event = require("event")
local computer = require("computer")

----------------------------------------

local skipcount = 0

----------------------------------------

local lib = {}

lib.createStream = function(name, ...)
    local obj = {}
    obj.name = name
    obj.thread = thread.create(function(...)
        while true do
            local eventData = {event.pull(...)}
            if skipcount == 0 then
                if eventData[1] and eventData[1] ~= "big_chat" and eventData[1] ~= "modem_message" then
                    pcall(bigchat.send, "eventTransfer"..name, table.unpack(eventData))
                end
            else
                skipcount = skipcount - 1
                if skipcount < 0 then skipcount = 0 end
            end
        end
    end, ...):detach()
    obj.kill = function() obj.thread:kill() end

    return obj
end

lib.connectStream = function(name)
    local obj = {}
    obj.name = name
    obj.listen = function(_, message_type, ...)
        if message_type == "eventTransfer"..obj.name then
            event.push(...)
            skipcount = skipcount + 1
        end
    end
    event.listen("big_chat", obj.listen)
    obj.kill = function() event.ignore("big_chat", obj.listen) end

    return obj
end

return lib