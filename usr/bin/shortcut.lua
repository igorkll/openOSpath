local simpleGui = require("simpleGui")
local term = require("term")
local computer = require("computer")
local fs = require("filesystem")

-----------------------------------------

local num = simpleGui.menu("select", {"back", "shutdown", "reboot", "lua", "event.log"})
term.clear()
if num == 2 then
    computer.shutdown()
elseif num == 3 then
    computer.shutdown(true)
elseif num == 4 then
    os.execute("lua")
elseif num == 5 then
    if fs.exists("/tmp/event.log") then
        os.execute("edit /tmp/event.log")
    else
        simpleGui.splash("event.log is not found")
    end
end
term.clear()