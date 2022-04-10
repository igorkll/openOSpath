local term = require("term")

------------------------------------

local lib = {}

function lib.getDepth()
    local gpu = term.gpu()
    local depth = math.floor(gpu.getDepth())
    return depth
end

function lib.getColorIndex()
    local depth = lib.getDepth()
    if depth == 4 then
        return {0xFFFFFF, 0xF2B233, 0xE57FD8, 0x99B2F2, 0xFEFE8C, 0x7FCC19, 0xFF8888, 0x4C4C4C, 0xAAAAAA, 0x3366CC, 0xFF33EE, 0x333999, 0xAA2222, 0x005500, 0xCC4C4C, 0x000000}
    else
        return {0xFFFFFF, 0xF2B233, 0xE57FD8, 0x99B2F2, 0xFEFE8C, 0x7FCC19, 0xF2B2CC, 0x4C4C4C, 0x999999, 0x4C99B2, 0xB266E5, 0x3366CC, 0x9F664C, 0x57A64E, 0xCC4C4C, 0x000000}
    end
end

function lib.getColors()
    local colorsIndex = lib.getColorIndex()

    local colors = {}
    colors.white = colorsIndex[1]
    colors.orange = colorsIndex[2]
    colors.magenta = colorsIndex[3]
    colors.lightBlue = colorsIndex[4]
    colors.yellow = colorsIndex[5]
    colors.lime = colorsIndex[6]
    colors.pink = colorsIndex[7]
    colors.gray = colorsIndex[8]
    colors.lightGray = colorsIndex[9]
    colors.cyan = colorsIndex[10]
    colors.purple = colorsIndex[11]
    colors.blue = colorsIndex[12]
    colors.brown = colorsIndex[13]
    colors.green = colorsIndex[14]
    colors.red = colorsIndex[15]
    colors.black = colorsIndex[16]
    return colors
end

function optimize(color)
    local depth = lib.getDepth()
    if depth == 4 and color == 0x00FFFF then color = 0x00AAFF end
    return color
end

function lib.reverse(color)
    color = 0xFFFFFF - color
    return color
end

function lib.hsvToRgb(h, s, v)
    h = h / 255
    s = s / 255
    v = v / 255

    local r, g, b

    local i = math.floor(h * 6);

    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);

    i = math.floor(i % 6)

    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    elseif i == 5 then
        r, g, b = v, p, q
    end

    r = math.floor(r * 255)
    g = math.floor(g * 255)
    b = math.floor(b * 255)

    return r, g, b
end

function lib.colorBlend(r, g, b)
    return b + (g * 256) + (r * 256 * 256)
end

return lib