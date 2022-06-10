local gui = require("simpleGui3").create()
local fs = require("filesystem")
local su = require("superUtiles")
local computer = require("computer")
local twicks = require("twicks")

---------------------------------------------

local function resetSettings()
    for i, v in ipairs(twicks.twicks()) do --отключаем все твики
        pcall(twicks.disable, v)
    end

    fs.remove("/usr/bin")
    fs.remove("/usr/lib")
    fs.remove("/start.lua")
    fs.remove("/autorun.lua")
    fs.remove("/autoruns/user")
    fs.remove("/home")
    fs.remove("/free")
    fs.remove("/afterUpdate.lua")
    fs.remove("/beforeUpdate.lua")

    su.saveFile("/home/.shrc", "")

    local bl = {
    "/etc/motd",
    "/etc/screen.cfg", --screen хоть и пользовательская настройка но сбивать я ее не хочу
    "/etc/rc.d",
    "/etc/rc.cfg",
    "/etc/profile.lua",
    }

    for file in fs.list("/etc") do
        local full_path = fs.concat("/etc", file)
        if not su.inTable(bl, full_path) then
            fs.remove(full_path)
        end
    end
end

---------------------------------------------

while true do
    local num = gui.menu("Settings", {"сброс на заводские настройки", "выход"})
    if num == 1 then
        gui.status([[
вы уверены что хотите сбросить устройство?
вы потеряете все свои данные и программы
все настройки также собьються
это поможет очистить устройство от вирусов
однако не от все
так же помните что сбрасываються только данных
пользователя все изменения внесенные в ос
не будут сброшены]], true)
        if gui.yesno("вы уверены произвести сброс настроек?") then
            resetSettings()
        end
    elseif num == 2 then
        gui.exit()
    end
end