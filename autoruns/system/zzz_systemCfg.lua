local serialization = require("serialization")
local su = require("superUtiles")
local fs = require("filesystem")
local event = require("event")
local component = require("component")
local term = require("term")
local computer = require("computer")
local shell = require("shell")
local uuid = require("uuid")

------------------------------------

_G.readonly = fs.get("/").isReadOnly()

if not fs.exists("/free/unical/systemUuid") then
    su.saveFile("/free/unical/systemUuid", uuid.next())
end

local function getType(checkType)
    local _, c = component.list(checkType)()
    return c
end

if not fs.exists("/free/unical/deviceType") then
    su.saveFile("/free/unical/deviceType", getType("tablet") or getType("robot") or getType("drone") or getType("microcontroller") or "computer")
end

if not fs.exists("/free/unical/deviceAddress") then
    su.saveFile("/free/unical/deviceAddress", computer.address())
end

su.saveFile("/free/current/systemUuid", uuid.next())
su.saveFile("/free/current/deviceAddress", computer.address())
su.saveFile("/free/current/deviceType", getType("tablet") or getType("robot") or getType("drone") or getType("microcontroller") or "computer")

------------------------------------

if not _G.recoveryMod then
    if fs.exists("/free/flags/error") then
        shell.execute("error", nil, su.getFile("/free/flags/error"))
    elseif fs.get("/").isReadOnly() then
        --os.execute("error \"drive is readonly\"")
    end
end

------------------------------------

local function updateValue(path)
    if fs.exists(path) then
        local count = tonumber(su.getFile(path))
        count = count + 1
        su.saveFile(path, tostring(count))
    else
        su.saveFile(path, "1")
    end
end

updateValue("/free/data/powerOnCount")

if fs.exists("/free/flags/powerOn") then
    updateValue("/free/data/powerWarning")
else
    su.saveFile("/free/flags/powerOn", "")
end
event.listen("shutdown", function()
    fs.remove("/free/flags/powerOn")
    updateValue("/free/data/likePowerOffCount")
end)

------------------------------------

function _G.saveSystemConfig()
    su.saveFile("/etc/system.cfg", serialization.serialize(_G.systemCfg or {updateErrorScreen = true, superHook = true, hook = true, shellAllow = true, autoupdate = false, updateRepo = "https://raw.githubusercontent.com/igorkll/openOSpath/main", updateVersionCfg = "/version.cfg", logo = true, startSound = true}))
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
    local color = 0x6699FF

    gui.status("при предидушем обновлениия произошла ошибка", 0xFFFFFF, color)
    os.sleep(2)
    gui.status("подлючите internet card, чтобы все исправить", 0xFFFFFF, color)
    os.sleep(2)
    gui.status("убедитесь что реальный пк подключен к интернету", 0xFFFFFF, color)
    os.sleep(2)
    computer.shutdown()
end

------------------------------------

--os.execute("lock -c")

if _G.systemCfg.logo and term.isAvailable() then
    local img
    local gpu = term.gpu()
    if math.floor(gpu.getDepth()) ~= 1 then
        if fs.exists("/etc/logo.pic") then
            img = require("imageDrawer").loadimage("/etc/logo.pic")
        elseif fs.exists("/etc/logoBW.pic") then
            img = require("imageDrawer").loadimage("/etc/logoBW.pic")
        end
    else
        if fs.exists("/etc/logoBW.pic") then
            img = require("imageDrawer").loadimage("/etc/logoBW.pic")
        elseif fs.exists("/etc/logo.pic") then
            img = require("imageDrawer").loadimage("/etc/logo.pic")
        end
    end
    if img then
        local rx, ry = gpu.getResolution()
        local cx, cy = img.getSize()
        cx, cy = (rx // 2) - (cx // 2), (ry // 2) - (cy // 2)
        img.draw(cx, cy)
    end
end
if _G.systemCfg.startSound and fs.exists("/etc/startSound.mid") then
    local function beep(n, d)
        if component.isAvailable("beep") then
            component.beep.beep({[n] = d})
        else
            computer.beep(n, d)
        end
    end
    require("midi2").create("/etc/startSound.mid", {beep}).play()
end

_G.updateRepo = systemCfg.updateRepo

if not _G.recoveryMod and not _G.readonly then
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
end

event.superHook = systemCfg.superHook
event.hook = systemCfg.hook
_G.shellAllow = systemCfg.shellAllow