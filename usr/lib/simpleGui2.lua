local term = require("term")
local unicode = require("unicode")
local event = require("event")
local process = require("process")
local su = require("superUtiles")

---------------------------------------------

local lib = {}

function lib.create(r, y)
    local obj = {}
    obj.back = 0xFFFFFF
    obj.main = 0
    obj.sub = 0x888888
    obj.char = " "
    obj.reset = su.saveGpu()

    ----------------------

    local gpu = term.gpu()
    local screen = term.screen()
    local keyboard = term.keyboard()

    if r and y then
        gpu.setResolution(r, y)
    end
    local rx, ry = gpu.getResolution()
    local depth = math.floor(gpu.getDepth())

    if depth == 1 then
        obj.sub = 0
    end
    obj.sub2 = obj.sub

    obj.gpu = gpu
    obj.screen = screen
    obj.keyboard = keyboard

    ----------------------

    function obj.exit()
        obj.reset()
        term.clear()
        os.exit()
    end
    process.info().data.signal = obj.exit

    ----------------------

    local function invert()
        gpu.setForeground(gpu.setBackground(gpu.getForeground()))
    end

    local function setColor(back, fore)
        gpu.setBackground(back or 0xFFFFFF)
        gpu.setForeground(fore or 0)
    end

    local function fill()
        gpu.fill(1, 1, rx, ry, obj.char)
    end

    local function clear(b, f)
        setColor(b or obj.back, f or obj.sub2)
        fill()
    end

    local function setText(text, posY)
        gpu.set(math.ceil((rx / 2) - (unicode.len(text) / 2)), posY, text)
    end

    ----------------------

    function obj.status(text, color)
        clear()
        setColor(obj.back, color or obj.main)
        setText(text, ry // 2)
    end

    function obj.menu(label, strs, num)
        local select = num or 1
        local posY = ((ry // 2) - (#strs // 2) - 1)
        if posY < 0 then posY = 0 end
        while true do
            clear()
            local startpos = (select // ry) * ry
            local dy = posY
            if startpos == 0 then
                setColor(obj.back, obj.main)
                setText(label, 1 + dy)
            else
                dy = 0
            end
            setColor(obj.back, obj.sub)
            for i = 1, #strs do
                local pos = (i + 1 + dy) - startpos
                if pos >= 1 and pos <= ry then
                    if keyboard and select == i then invert() end
                    setText(strs[i], pos)
                    if keyboard and select == i then invert() end
                end
            end
            local eventName, uuid, _, code, button = event.pull()
            if eventName == "key_down" and uuid == keyboard then
                if code == 200 and select > 1 then
                    select = select - 1
                end
                if code == 208 and select < #strs then
                    select = select + 1
                end
                if code == 28 then
                    return select, strs[select]
                end
            elseif eventName == "touch" and uuid == screen and button == 0 then
                code = (code + startpos) - dy
                code = code - 1
                if code >= 1 and code <= #strs then
                    return code, strs[code]
                end
            elseif eventName == "scroll" and uuid == screen then
                if button == 1 and select > 1 then
                    select = select - 1
                end
                if button == -1 and select < #strs then
                    select = select + 1
                end
            end
        end
    end

    function obj.yesno(label, simple)
        if simple then
            return obj.menu(label, {"no", "yes"}) == 2
        else
            return obj.menu(label, {"no", "no", "yes", "no"}) == 3
        end
    end

    function obj.splash(str, color)
        clear()
        setColor(obj.back, color or obj.main)
        gpu.set(1, 1, str)
        setColor(obj.back, obj.main)
        gpu.set(1, 2, "press enter or touch to continue...")
        while true do
            local eventName, uuid, _, code = event.pull()
            if eventName == "key_down" and uuid == keyboard then
                if code == 28 then
                    break
                end
            elseif eventName == "touch" and uuid == screen then
                break
            end
        end
    end

    function obj.inputZone(text)
        clear()
        setColor(obj.back, obj.main)
        term.setCursor(1, 1)
        term.write(text .. ": ")
        return io.read()
    end

    return obj
end

return lib