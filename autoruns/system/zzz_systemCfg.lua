local serialization = require("serialization")
local su = require("superUtiles")
local fs = require("filesystem")
local event = require("event")
local component = require("component")
local term = require("term")
local computer = require("computer")

------------------------------------

function _G.saveSystemConfig()
    su.saveFile("/etc/system.cfg", serialization.serialize(_G.systemCfg or {updateErrorScreen = true, superHook = true, hook = true, shellAllow = true, autoupdate = false, updateRepo = "https://raw.githubusercontent.com/igorkll/openOSpath/main", updateVersionCfg = "/version.cfg"}))
end

if not fs.exists("/etc/system.cfg") then saveSystemConfig() end
_G.systemCfg = assert(serialization.unserialize(assert(su.getFile("/etc/system.cfg"))))

------------------------------------

function _G.updateNoInternetScreen()
    event.superHook = false
    if not term.isAvailable() or not _G.systemCfg.updateErrorScreen then computer.shutdown(true) end

    local rx, ry = 50, 16
    if component.isAvailable("tablet") then
        rx, ry = term.gpu().maxResolution()
    end

    local gui = require("simpleGui2").create(rx, ry)
    local color = require("colorPic").getColors().lightBlue

    while true do
        gui.status("при предидушем обновлениия произошла ошибка", 0xFFFFFF, color)
        os.sleep(2)
        gui.status("подлючите internet card, чтобы все исправить", 0xFFFFFF, color)
        os.sleep(2)
        gui.status("убедитесь что реальный пк подключен к интернету", 0xFFFFFF, color)
        os.sleep(2)
        gui.status("после испровления подключения перезагрузите", 0xFFFFFF, color)
        os.sleep(2)
    end
end

------------------------------------

--os.execute("lock -c")

_G.updateRepo = systemCfg.updateRepo

local isInternet = su.isInternet()
if systemCfg.autoupdate or fs.exists("/free/flags/updateStart") then
    if fs.exists("/free/flags/updateStart") then
        if isInternet then
            os.execute("fastupdate -f")
        else
            _G.updateNoInternetScreen()
        end
    else
        if isInternet then
            os.execute("fastupdate")
        end
    end
end

event.superHook = systemCfg.superHook
event.hook = systemCfg.hook
_G.shellAllow = systemCfg.shellAllow