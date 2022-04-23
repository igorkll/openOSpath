if computer.setArchitecture then pcall(computer.setArchitecture, "Lua 5.3") end --зашита от моих биосов(они усторели и удин удаляет setArchitecture а другой заставляет его выдать ошибку)

-----------------------------------mods

do
    local atan = math.atan
    function math.atan2(y, x)
        return atan(y / x)
    end
end

do --для таблиц в event
    local buffer = {}

    local oldPull = computer.pullSignal
    local oldPush = computer.pushSignal
    local tinsert = table.insert
    local tunpack = table.unpack
    local tremove = table.remove

    function computer.pullSignal(timeout)
        if #buffer == 0 then
            return oldPull(timeout)
        else
            local data = buffer[1]
            tremove(buffer, 1)
            return tunpack(data)
        end
    end

    function computer.pushSignal(...)
        tinsert(buffer, {...})
        return true
    end
end

do --спяший режим
    local computer_pullSignal = computer.pullSignal
    local computer_pushSignal = computer.pushSignal
    local computer_uptime = computer.uptime
    local table_unpack = table.unpack
    local checkArg = checkArg

    local uptimeAdd = 0
    function computer.uptime()
        return computer_uptime() + uptimeAdd
    end

    function computer.sleep(time, saveEvent, doNotCorectUptime)
        checkArg(1, time, "number")
        checkArg(2, saveEvent, "nil", "boolean")
        checkArg(3, doNotCorectUptime, "nil", "boolean")
        local inTime = computer_uptime()
        while computer_uptime() - inTime < time do
            local eventData = {computer_pullSignal(time - (computer_uptime() - inTime))}
            if saveEvent then
                computer_pushSignal(table_unpack(eventData))
            end
        end
        if not doNotCorectUptime then
            uptimeAdd = uptimeAdd - (computer_uptime() - inTime)
        end
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
    do 
        local path = "/free/twicks/mem/"
        local tbl = component.proxy(computer.getBootAddress()).list(path) or {}
        table.sort(tbl)
        for i, v in ipairs(tbl) do
            local full_path = path .. v
            loadfile(full_path)()
        end
    end
    loadfile("/lib/core/boot.lua")(loadfile)
end

-----------------------------------

local fs = require("filesystem")
local term = require("term")
local event = require("event")
local component = require("component")
local computer = require("computer")
local su = require("superUtiles")

-----------------------------------

local autorunspath = "/autoruns" --блок упровления автозагрузкой
local systemautoruns = fs.concat(autorunspath, "system")
local userautoruns = fs.concat(autorunspath, "user")
local afterBootTwicks = "/free/twicks/afterBoot1"

local function list(path)
    local tbl = fs.get(path).list(path)
    table.sort(tbl)
    return ipairs(tbl)
end

-----------------------------------

fs.makeDirectory("/free/flags")

if fs.exists(afterBootTwicks) then --запуск boot твиков после запуска класической openOS
    for _, data in list(afterBootTwicks) do
        os.execute(fs.concat(afterBootTwicks, data))
    end
end

-----------------------------------

if fs.exists(systemautoruns) then --системная автозагрузка
    for _, data in list(systemautoruns) do
        os.execute(fs.concat(systemautoruns, data))
    end
end

if fs.exists("/free/flags/updateEnd") then --запуска файла дополнения обновления(для оболочек)
    local afterUpdate = false
    if fs.exists("/afterUpdate.lua") then
        local ok, err = sdofile("/afterUpdate.lua")
        if not ok then
            su.logTo("/free/logs/afterUpdateError.log", err or "unkown")
            computer.shutdown(true)
            return
        end
        afterUpdate = true
    end
    fs.remove("/free/flags/updateEnd")
    if afterUpdate then
        computer.shutdown(true)
        return
    end
end

-----------------------------------экран блокировки

os.execute("lock -c")

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