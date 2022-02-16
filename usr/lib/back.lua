local thread = require("thread")
local shell = require("shell")

--сорян за говно код

------------------------------------------

if not programm_loaded then programm_loaded = {} end

------------------------------------------

local lib = {}

function lib.list()
    local list = {}
    for name in pairs(programm_loaded) do
        list[#list + 1] = name
    end
    return list
end

function lib.getArray()
    return programm_loaded
end

function lib.stop(name)
    checkArg(1, name, "string")
    local t = programm_loaded[name]
    if not t then return nil, "this programm is not loaded" end
    return t:suspend()
end

function lib.start(name)
    checkArg(1, name, "string")
    local t = programm_loaded[name]
    if not t then return nil, "this programm is not loaded" end
    return t:resume()
end

function lib.kill(name)
    checkArg(1, name, "string")
    local t = programm_loaded[name]
    if not t then return nil, "this programm is not loaded" end
    programm_loaded[name] = nil
    return t:kill()
end

function lib.getProgramm(name)
    checkArg(1, name, "string")
    return programm_loaded[name]
end

function lib.load(path, name, ...)
    checkArg(1, path, "string")
    checkArg(2, name, "string")
    if programm_loaded[name] then return "this name exists" end

    local func, err = loadfile(path)
    if not func then return nil, err end
    os.setenv("_", path)
    local th = thread.create(func, ...)
    th:detach()
    programm_loaded[name] = th

    return th
end

function lib.loadData(func, name, ...)
    checkArg(1, func, "string")
    checkArg(2, name, "string")
    if programm_loaded[name] then return "this name exists" end

    local th = thread.create(func, ...)
    th:detach()
    programm_loaded[name] = th

    return th
end

return lib