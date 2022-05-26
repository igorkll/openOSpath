local gpu = require("term").gpu()
local su = require("superUtiles")
local colorPic = require("colorPic")

for i = 0, 15 do --сброс палитры, она должна быть определена в автозагрузке и точька
    local count = su.mapClip(i, 0, 15, 0, 255)
    gpu.setPaletteColor(i, colorPic.colorBlend(count, count, count))
end