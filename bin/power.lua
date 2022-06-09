local computer = require("computer")
local su = require("superUtiles")

---------------------------------------------

print(tostring(su.floorAt(su.mapClip(computer.energy(), 0, computer.maxEnergy(), 0, 100), 0.1)) .. "%")