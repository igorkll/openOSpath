local serialization = require("serialization")
local su = require("superUtiles")
local fs = require("filesystem")
local event = require("event")

------------------------------------

if not fs.exists("/etc/system.cfg") then
    su.saveFile("/etc/system.cfg", serialization.serialize({superHook = true, hook = true, shellAllow = true}))
end

local systemCfg = assert(serialization.unserialize(assert(su.getFile("/etc/system.cfg"))))

------------------------------------

event.superHook = systemCfg.superHook
event.hook = systemCfg.hook
_G.shellAllow = systemCfg.shellAllow