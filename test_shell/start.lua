local term = require("term")
local computer = require("computer")

-------------------------------------

local setCount = 0
if systemCfg.autoupdate then
    systemCfg.autoupdate = false
    setCount = setCount + 1
end
if systemCfg.shellAllow then
    systemCfg.shellAllow = false
    setCount = setCount + 1
end
if systemCfg.superHook then
    systemCfg.superHook = false
    setCount = setCount + 1
end
if setCount > 0 then
    saveSystemConfig()
    computer.shutdown(true)
end

-------------------------------------

local systemUpdated = dofile("/usr/bin/fastupdate.lua", "-n")
if systemUpdated then
    dofile("/usr/bin/fastupdate.lua", "https://raw.githubusercontent.com/igorkll/openOSpath/main/test_shell", "/test_shell_version.cfg", "-f")
else
    dofile("/usr/bin/fastupdate.lua", "https://raw.githubusercontent.com/igorkll/openOSpath/main/test_shell", "/test_shell_version.cfg")
end

-------------------------------------


local gpu = term.gpu()
gpu.setBackground(0xFFFF00)
gpu.setForeground(0)
os.execute("edit -r /text.txt")
