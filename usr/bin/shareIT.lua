local networks = require("networks")
local shell = require("shell")
local fs = require("filesystem")
local su = require("superUtiles")
local event = require("event")

----------------------------------------------------

local args, options = shell.parse(...)

local network, name
if args[1] then
    network = networks.getNetwork(args[2])
    if not network then io.stderr:write("this network in not open\n") return end
    name = args[4]
    if not name then io.stderr:write("name is not enter\n") return end
end

----------------------------------------------------

if args[1] == "send" then
    local path = shell.resolve(args[3])
    if not path then io.stderr:write("path is not enter\n") return end
    if not fs.exists(path) then io.stderr:write("file is not found\n") return end
    if fs.isDirectory(path) then io.stderr:write("isDirectory\n") return end

    if not options.q then print("ожидания...") end
    while true do
        local eventData = {event.pull("network_message", network.name)}
        if eventData[3] == "shareIT" and eventData[4] == "requireFile" and eventData[5] == name then
            network.send("shareIT", "fileData", name, assert(su.getFile(path)))
            if not options.q then print("вайл передан") end
        end
    end
elseif args[1] == "get" then
    local path = shell.resolve(args[3])
    if not path then io.stderr:write("path is not enter\n") return end
    if fs.exists(path) and not options.f then io.stderr:write("file is exists\n") return end

    if not options.q then print("ожидания...") end
    network.send("shareIT", "requireFile", name)
    while true do
        local eventData = {event.pull("network_message", network.name)}
        if eventData[3] == "shareIT" and eventData[4] == "fileData" and eventData[5] == name then
            su.saveFile(path, eventData[6])
            if not options.q then print("вайл принят") end
            break
        end
    end
elseif not options.q then
    print("send network path name")
    print("get network path name")
end