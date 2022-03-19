local serialization = require("serialization")
local su = require("superUtiles")
local fs = require("filesystem")
local event = require("event")
local component = require("component")

------------------------------------

if not fs.exists("/etc/system.cfg") then
    su.saveFile("/etc/system.cfg", serialization.serialize({superHook = true, hook = true, shellAllow = true, autoupdate = false}))
end
local systemCfg = assert(serialization.unserialize(assert(su.getFile("/etc/system.cfg"))))

------------------------------------

if systemCfg.autoupdate and component.isAvailable("internet") then
    os.execute("fastupdate")
end

event.superHook = systemCfg.superHook
event.hook = systemCfg.hook
_G.shellAllow = systemCfg.shellAllow