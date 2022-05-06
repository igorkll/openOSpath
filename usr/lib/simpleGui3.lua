local su = require("superUtiles")
local component = require("component")
local unicode = require("unicode")
local term = require("term")
local event = require("event")
local process = require("process")
local computer = require("computer")

return {create = function()
    local lib = {}
    lib.gpu = term.gpu()
    lib.screen = term.screen()
    lib.keyboard = term.keyboard()

    lib.depth = math.floor(lib.gpu.getDepth())
    lib.rx, lib.ry = lib.gpu.getResolution()
    
    function lib.selectColor(mainColor, simpleColor, bw)
        if type(bw) == "boolean" then bw = bw and 0xFFFFFF or 0 end
        if lib.depth == 4 then
            return simpleColor or mainColor
        elseif lib.depth == 1 then
            return bw
        else
            return mainColor
        end
    end

    lib.blackColor = 0
    lib.whiteColor = 0xFFFFFF
    lib.grayColor = lib.selectColor(0x888888, 0x222222, false)

    function lib.setColor(back, fore)
        lib.gpu.setBackground(back or lib.whiteColor)
        lib.gpu.setForeground(fore or lib.blackColor)
    end

    function lib.clear(back, fore)
        lib.setColor(back, fore)
        lib.gpu.fill(1, 1, lib.rx, lib.ry, " ")
    end

    function lib.invert()
        lib.gpu.setForeground(lib.gpu.setBackground(lib.gpu.getForeground()))
    end

    function lib.setText(text, posY)
        lib.gpu.set((lib.rx // 2) - (unicode.len(text) // 2), posY, text)
    end

    lib.isControl = lib.screen and (lib.keyboard or (math.floor(computer.getDeviceInfo()[lib.screen].width) ~= 1))

    function lib.status(text, del)
        if not lib.isControl and del == true then del = 1 end

        local texts = su.splitText(text, "\n")
        if del == true then
            table.insert(texts, "press enter or touch to continue")
        end

        lib.clear()
        for i, v in ipairs(texts) do
            lib.setText(v, ((lib.ry // 2) - (#texts // 2)) + (i - 1))
        end
        
        if del == true then
            while true do
                local eventData, uuid, _, code, button = event.pull()
                if eventData == "touch" and uuid == lib.screen and button == 0 then
                    break
                elseif eventData == "key_down" and uuid == lib.keyboard and code == 28 then
                    break
                end
            end
        elseif del then
            os.sleep(del)
        end
    end

    function lib.input(text, crypto)
        if not lib.keyboard then
            lib.splash("keyboard is not found")
            return ""
        end
        local buffer = ""
        local center = lib.ry // 2
        local function redraw()
            lib.clear()
            local buffer = buffer
            if crypto then
                buffer = string.rep("*", unicode.len(buffer))
            end
    
            local drawtext = (text and (text .. ": ") or "") .. buffer .. "_"
            lib.setText(drawtext, center)
        end
    
        while true do
            redraw()
            local eventName, uuid, char, code = event.pull()
            if eventName == "key_down" and uuid == lib.keyboard then
                if code == 28 then
                    return buffer
                elseif code == 14 then
                    if unicode.len(buffer) > 0 then
                        buffer = unicode.sub(buffer, 1, unicode.len(buffer) - 1)
                        redraw()
                    end
                elseif char ~= 0 then
                    buffer = buffer .. unicode.char(char)
                    redraw()
                end
            elseif eventName == "clipboard" and uuid == lib.keyboard then
                buffer = buffer .. char
                if unicode.sub(char, unicode.len(char), unicode.len(char)) == "\n" then
                    return unicode.sub(buffer, 1, unicode.len(buffer) - 1)
                end
            elseif eventName == "touch" and uuid == lib.screen then
                if #buffer == 0 then
                    return ""
                end
            end
        end
    end

    function lib.menu(label, strs, num)
        local pos, posY, oldpos = num or 1, (lib.ry // 2) - (#strs // 2)
        if posY < 1 then posY = 1 end
        while true do
            local startpos = (pos // lib.ry) * lib.ry

            if pos ~= oldpos then
                lib.clear()
                if startpos == 0 then
                    lib.setColor(lib.selectColor(lib.whiteColor, nil, lib.blackColor), lib.selectColor(lib.blackColor, nil, lib.whiteColor))
                    lib.setText(label, posY)
                end
                lib.setColor(lib.whiteColor, lib.selectColor(lib.grayColor, nil, lib.blackColor))
                for i = 1, #strs do
                    local drawpos = (posY + i) - startpos
                    if drawpos >= 1 then
                        if drawpos > lib.ry then break end
                        if i == pos then lib.invert() end
                        lib.setText(strs[i], drawpos)
                        if i == pos then lib.invert() end
                    end
                end
            end

            local eventData = {event.pull()}
            oldpos = pos
            if eventData[1] == "key_down" and eventData[2] == lib.keyboard then
                if eventData[4] == 28 then
                    break
                elseif eventData[4] == 200 then
                    pos = pos - 1
                    if pos < 1 then pos = 1 end
                elseif eventData[4] == 208 then
                    pos = pos + 1
                    if pos > #strs then pos = #strs end
                end
            elseif eventData[1] == "scroll" and eventData[2] == lib.screen and lib.keyboard then --проверка наличия клавиатуры потому что указатель без нее не отображаеться, если у меню был бы звук то на планшети без клавиатуры он не должег проигроваться при scroll
                pos = pos - eventData[5]
                if pos < 1 then pos = 1 end
                if pos > #strs then pos = #strs end
            elseif eventData[1] == "touch" and eventData[2] == lib.screen and eventData[5] == 0 then
                local ty = eventData[4] - posY
                if ty > 1 and ty < #strs then
                    pos = ty
                    break
                end
            end
        end
        return pos, strs[pos]
    end

    function lib.exit()
        lib.gpu.setBackground(0)
        lib.gpu.setForeground(0xFFFFFF)
        term.clear()
        os.exit()
    end
    process.info().data.signal = lib.exit

    return lib
end}