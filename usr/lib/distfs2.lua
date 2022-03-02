local event = require("event")
local networks = require("networks")
local fs = require("filesystem")
local proxyFS = require("proxyFS")

-----------------------------------

local appkey = "distfs2"

-----------------------------------

local lib = {}

lib.hosts = {}
lib.connects = {}

function lib.create(network, index, folder, readonly, maxSize, freeSize, maxFiles)
    local obj = {}
    obj.network = network
    obj.index = index
    obj.folder = folder
    obj.readonly = readonly
    obj.openFiles = {}
    obj.maxSize = maxSize
    obj.freeSize = freeSize
    obj.maxFiles = maxFiles
    obj.proxyFS = (type(obj.folder) == "table" and obj.folder) or proxyFS.createFS(obj.folder, index, true)

    -----------------------------------

    local function openFileAllow(isWrite)
        local tfs = (type(obj.folder) == "table" and obj.folder) or fs.get(obj.folder)
        if obj.maxFiles and #obj.openFiles >= obj.maxFiles then return false end
        if isWrite then
            local ok1 = not obj.maxSize or (tfs.spaceUsed() <= obj.maxSize)
            local ok2 = not obj.freeSize or (tfs.spaseTotal() - tfs.spaceUsed() > obj.freeSize)
            return ok1 and ok2
        end
        return true
    end

    local function send(...)
        obj.network.send(appkey, obj.index, ...)
    end

    local function returnData(...)
        send("return", ...)
    end

    local function returnValue(...)
        returnData("out", ...)
    end

    local function returnCommand(...)
        returnData("command", ...)
    end

    -----------------------------------

    local function listen(_, net, mainkey, index, side, command, ...)
        if net == obj.network.name and mainkey == appkey and index == obj.index and side == "call" then
            local arg = {...}
            if command == "open" then
                local path, mode = arg[1], arg[2]
                local isWrite = mode:sub(1, 1) == "w"
                if obj.readonly and isWrite then returnValue(nil, "filesystem is readonly") return end
                if not openFileAllow(isWrite) then returnValue(nil, "open in not allow") return end

                local file, err = obj.proxyFS.open(path, mode)
                if not file then returnValue(nil, err) return end

                table.insert(obj.openFiles, file)
                returnValue(#obj.openFiles)
            elseif command == "close" then
                local index = arg[1]
                local file = obj.openFiles[index]
                if not file then returnValue(nil, "file is not open") return end
                file:close()
                table.remove(obj.openFiles, index)
                returnCommand("nup")
            elseif command == "read" then
                local index, num = arg[1], arg[2]
                local file = obj.openFiles[index]
                if not file then returnValue(nil, "file is not open") return end
                returnValue(file:read(num))
            elseif command == "write" then
                local index, data = arg[1], arg[2]
                local file = obj.openFiles[index]

                if not file then returnValue(nil, "file is not open") return end
                if not openFileAllow(true) then returnValue(nil, "write in not allow") return end

                returnValue(file:write(data))
            elseif command == "seek" then
                local index, data1, data2 = arg[1], arg[2], arg[3]
                local file = obj.openFiles[index]
                if not file then returnValue(nil, "file is not open") return end
                returnValue(file:seek(data1, data2))
            elseif command == "spaseUsed" then
                returnValue(0)
            elseif command == "spaseTotal" then
                returnValue(math.huge)
            elseif command == "size" then
                local path = arg[1]
                returnValue(obj.proxyFS.size(path))
            elseif command == "makeDirectory" then
                local path = arg[1]
                if obj.readonly then returnValue(nil, "filesystem is readonly") return end
                returnValue(obj.proxyFS.makeDirectory(path))
            elseif command == "remove" then
                local path = arg[1]
                if obj.readonly then returnValue(nil, "filesystem is readonly") return end
                returnValue(obj.proxyFS.remove(path))
            elseif command == "rename" then
                local path, path2 = arg[1], arg[2]
                if obj.readonly then returnValue(nil, "filesystem is readonly") return end
                returnValue(obj.proxyFS.rename(path, path2))
            elseif command == "exists" then
                local path = arg[1]
                returnValue(obj.proxyFS.exists(path))
            elseif command == "isDirectory" then
                local path = arg[1]
                returnValue(obj.proxyFS.isDirectory(path))
            elseif command == "isReadOnly" then
                returnValue(obj.readonly)
            elseif command == "lastModified" then
                local path = arg[1]
                returnValue(obj.proxyFS.lastModified(path))
            elseif command == "list" then
                local path = arg[1]
                returnValue(obj.proxyFS.list(path))
            elseif command == "getLabel" then
                returnValue(index)
            elseif command == "setLabel" then
                returnCommand("nup")
            end
        end
    end
    event.listen("network_message", listen)

    function obj.kill()
        event.ignore("network_message", listen)
    end

    table.insert(lib.hosts, obj)
    return obj
end

function lib.getDistFs(network, index)
    local obj = {}
    obj.network = network
    obj.index = index

    -----------------------------------

    local function send(...)
        obj.network.send(appkey, obj.index, ...)
    end

    local function call(...)
        send("call", ...)
    end

    -----------------------------------

    local pfs = {}
    local functions = {"list", "open", "close", "read", "write", "seek", "rename", "remove", "exists", "isDirectory", "getLabel", "setLabel", "isReadOnly", "lastModified", "makeDirectory", "size", "spaceTotal", "spaceUsed"}
    for i = 1, #functions do
        local name = functions[i]
        pfs[name] = function(...)
            call(name, ...)
            local eventData = {event.pull(4, "network_message", obj.network.name, appkey, obj.index, "return")}
            local out = {table.unpack(eventData, 6, #eventData)}
            if out[1] == "out" then
                return table.unpack(eventData, 7, #eventData)
            else
                return nil, "no connections"
            end
        end
    end

    -----------------------------------

    return obj, pfs
end

function lib.connect(network, index, folder)
    local obj, pfs = lib.getDistFs(network, index)
    obj.folder = folder
    fs.mount(pfs, obj.folder)
    table.insert(lib.connects, {obj, pfs})
    return obj, pfs
end

function lib.getFs(name)
    for i = 1, #lib.hosts do
        if lib.hosts[i].index == name then
            return lib.hosts[i]
        end
    end
end

return lib