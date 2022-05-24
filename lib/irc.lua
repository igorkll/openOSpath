local internet = require("internet")
local thread = require("thread")
local event = require("event")
local su = require("superUtiles")

--------------------------------------------

local lib = {}

function lib.create(objname, hostname, port, nikname)
    local obj = {}
    obj.tcp = assert(internet.open(hostname, port))
    obj.objname = objname
    obj.channel = nil

    obj.tcp:setTimeout(0.5)

    function obj.rawSend(data)
        obj.tcp:write(data .. "\r\n")
        obj.tcp:flush()
    end
    obj.rawSend("USER " .. nikname .. " 0 * :" .. nikname)
    obj.rawSend("NICK :" .. nikname)

    function obj.join(name)
        obj.rawSend("JOIN :" .. name)
        obj.channel = name
    end

    function obj.channels()
        
    end

    function obj.send(text)
        if not obj.channel then return nil, "first you need to log in to the channel" end
        obj.rawSend("PRIVMSG " .. obj.channel .. " :" .. text)
        return true
    end

    obj.thread = thread.create(function()
        local function loop()
            while true do
                local ok, tcpRead = pcall(function() return obj.tcp:read() end)
                if ok and tcpRead then
                    if tcpRead:sub(1, 4) == "PING" then
                        obj.rawSend("PONG" .. tcpRead:sub(5, #tcpRead))
                    else
                        event.push("raw_irc_message", obj.objname, tcpRead)
    
                        do
                            local data = su.split(tcpRead, " PRIVMSG ")[2]
                            if data then
                                local channelName = data:match("[^%s]+")
                                local data2 = su.split(tcpRead, channelName .. " ")[2]
                                local rawNikname = data2:match("[^%s]+")
                                local nikname = rawNikname:sub(2, #rawNikname - 1)
                                local message = su.split(tcpRead, rawNikname .. " ")[2]

                                event.push("privmsg_irc_message", obj.objname, channelName, nikname, message)
                            end
                        end
                    end
                else
                    os.sleep(1)
                end
            end
        end
        ::tonew::
        local ok, err = pcall(loop)
        if not ok then
            event.push("irc_thread_crash", obj.objname, err or "unkown")
            su.logTo("/free/logs/irc", "obj: " .. obj.objname .. ", error: " .. (err or "unkown"))
            os.sleep(1)
            goto tonew
        end
    end)
    obj.thread:detach()

    function obj.kill()
        obj.rawSend("QUIT")
        obj.tcp:close()
        obj.thread:kill()
    end

    return obj
end

return lib