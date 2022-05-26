local gpu = require("term").gpu()
local su = require("superUtiles")
local colorPic = require("colorPic")

if gpu.getDepth() == 4 then
    for i, v in ipairs(colorPic.getColorIndex()) do--цвета на 4 bit будут мягче и почьти все оналогичьны computer craft
        gpu.setPaletteColor(i - 1, v)
    end
elseif gpu.getDepth() == 8 then
    for i = 0, 15 do --сброс палитры, она должна быть определена в автозагрузке и точька
        local count = su.mapClip(i, 0, 15, 0, 255)
        gpu.setPaletteColor(i, colorPic.colorBlend(count, count, count))
    end
end