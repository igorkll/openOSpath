do
    local addr, invoke = computer.getBootAddress(), component.invoke
    local function loadfile(file)
        local handle = assert(invoke(addr, "open", file))
        local buffer = ""
        repeat
            local data = invoke(addr, "read", handle, math.huge)
            buffer = buffer .. (data or "")
        until not data
        invoke(addr, "close", handle)
        return load(buffer, "=" .. file, "bt", _G)
    end
    loadfile("/lib/core/boot.lua")(loadfile)
end

-----------------------------------

local fs = require("filesystem")

local autorunspath = "/autoruns"
local systemautoruns = fs.concat(autorunspath, "system")
local userautoruns = fs.concat(autorunspath, "user")

local function list(path)
    local tbl = fs.get(path).list(path)
    table.sort(tbl)
    return ipairs(tbl)
end

if fs.exists(systemautoruns) then
    for _, data in list(systemautoruns) do
        os.execute(fs.concat(systemautoruns, data))
    end
end

-----------------------------------

if fs.exists("/start.lua") then
    os.execute("/start.lua")
elseif fs.exists("/.start.lua") then
    os.execute("/.start.lua")
elseif fs.exists("/autorun.lua") then
    os.execute("/autorun.lua")
elseif fs.exists("/.autorun.lua") then
    os.execute("/.autorun.lua")
end

-----------------------------------

if fs.exists(userautoruns) then
    for _, data in list(userautoruns) do
        os.execute(fs.concat(userautoruns, data))
    end
end

-----------------------------------

while true do
    local result, reason = xpcall(require("shell").getShell(), function(msg)
        return tostring(msg) .. "\n" .. debug.traceback()
    end)
    if not result then
        io.stderr:write((reason ~= nil and tostring(reason) or "unknown error") .. "\n")
        io.write("Press any key to continue.\n")
        os.sleep(0.5)
        require("event").pull("key")
    end
end