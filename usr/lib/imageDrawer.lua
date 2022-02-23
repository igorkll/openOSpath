local term = require("term")
local fs = require("filesystem")
local colorPic = require("colorPic")

-----------------------------------------

local lib = {}

lib.gpu = term.gpu()
lib.colors = colorPic.getColorIndex()

function lib.loadimage(path)
    checkArg(1, path, "string")

    -----------------------------------------

    local obj = {}
    obj.image = {}
    obj.colors = lib.colors

    if path then
        local file = assert(io.open(path))
        while true do
            local line = file:read()
            if not line then break end
            table.insert(obj.image, line)
        end
        file:close()
    end
    
    function obj.draw(posX, posY)
        checkArg(1, posX, "number")
        checkArg(2, posY, "number")

        -----------------------------------------

        local gpu = lib.gpu
        local image = obj.image
        local colors = obj.colors

        local oldb = gpu.getBackground()
        for linecount = 1, #image do
            local line = image[linecount]
            for pixelcount = 1, #line do
                local pixel = line:sub(pixelcount, pixelcount)
                local number = tonumber(pixel, 16)
                if number then
                    gpu.setBackground(colors[number + 1])
                    gpu.set(posX + (pixelcount - 1), posY + (linecount - 1), " ")
                end
            end
        end
        gpu.setBackground(oldb)
    end

    return obj
end

return lib