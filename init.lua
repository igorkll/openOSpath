if computer.setArchitecture then pcall(computer.setArchitecture, "Lua 5.3") end --зашита от моих биосов(они усторели и удин удаляет setArchitecture а другой заставляет его выдать ошибку)

do --для таблиц в event
    local buffer = {}

    local oldPull = computer.pullSignal
    local oldPush = computer.pushSignal

    function computer.pullSignal(timeout)
        if #buffer == 0 then
            return oldPull(timeout)
        else
            local data = buffer[1]
            table.remove(buffer, 1)
            return table.unpack(data)
        end
    end

    function computer.pushSignal(...)
        table.insert(buffer, {...})
        return true
    end
end

-----------------------------------

do --активатор загрузчика
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
local term = require("term")
local event = require("event")
local component = require("component")
local computer = require("computer")

-----------------------------------

local autorunspath = "/autoruns" --блок упровления автозагрузкой
local systemautoruns = fs.concat(autorunspath, "system")
local userautoruns = fs.concat(autorunspath, "user")

local function list(path)
    local tbl = fs.get(path).list(path)
    table.sort(tbl)
    return ipairs(tbl)
end

-----------------------------------

fs.makeDirectory("/free/flags")

if fs.exists(systemautoruns) then --системная автозагрузка
    for _, data in list(systemautoruns) do
        os.execute(fs.concat(systemautoruns, data))
    end
end

if fs.exists("/free/flags/updateEnd") then
    local afterUpdate = false
    if fs.exists("/afterUpdate.lua") then
        os.execute("/afterUpdate.lua")
        afterUpdate = true
    end
    fs.remove("/free/flags/updateEnd")
    if afterUpdate then
        computer.shutdown(true)
    end
    return
end

-----------------------------------

_G.runlevel = 1
event.push("init") --подтверждает инициализацию системмы
event.pull(1, "init")

-----------------------------------

_G.externalAutoruns = true --разришить автозогрузку с внешних насителей
for address in component.list("filesystem") do
    event.push("autorun", address) --инициирует автозагрузки
end
for i = 1, 2 do os.sleep(0.2) end

-----------------------------------

if fs.exists("/.start.lua") then --главная автозагрузка
    os.execute("/.start.lua")
elseif fs.exists("/.autorun.lua") then
    os.execute("/.autorun.lua")
end

if fs.exists("/autorun.lua") then os.execute("/autorun.lua") end
if fs.exists("/start.lua") then os.execute("/start.lua") end

-----------------------------------

if fs.exists(userautoruns) then --автозагрузка пользователя
    for _, data in list(userautoruns) do
        os.execute(fs.concat(userautoruns, data))
    end
end

-----------------------------------

local function waitFoEnter()
    os.sleep(0.5)
    while true do
        local _, uuid, _, code = event.pull("key_down")
        if term.keyboard() and uuid == term.keyboard() and code == 28 then
            break
        end
    end
end

while _G.shellAllow do --запуск shell
    local result, reason = xpcall(require("shell").getShell(), function(msg)
        return tostring(msg) .. "\n" .. debug.traceback()
    end)
    if not result and term.isAvailable() then
        io.stderr:write((reason ~= nil and tostring(reason) or "unknown error") .. "\n")
        io.write("Press enter key to continue.\n")
        waitFoEnter()
    end
end
io.write("Shell is not allow, press enter key to reboot.\n")
waitFoEnter()
computer.shutdown(true)