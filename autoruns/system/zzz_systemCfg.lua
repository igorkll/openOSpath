local serialization = require("serialization")
local su = require("superUtiles")
local fs = require("filesystem")
local event = require("event")
local component = require("component")

------------------------------------

function _G.saveSystemConfig()
    su.saveFile("/etc/system.cfg", serialization.serialize({superHook = true, hook = true, shellAllow = true, autoupdate = false, updateRepo = "https://raw.githubusercontent.com/igorkll/openOSpath/main"}))
end

if not fs.exists("/etc/system.cfg") then saveSystemConfig() end
_G.systemCfg = assert(serialization.unserialize(assert(su.getFile("/etc/system.cfg"))))

------------------------------------

_G.updateRepo = systemCfg.updateRepo

if systemCfg.autoupdate and component.isAvailable("internet") then
    os.execute("fastupdate")
end

event.superHook = systemCfg.superHook
event.hook = systemCfg.hook
_G.shellAllow = systemCfg.shellAllow