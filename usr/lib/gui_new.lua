local component = require("component")
local event = require("event")
local term = require("term")
local unicode = require("unicode")
local thread = require("thread")
local computer = require("computer")

--------------------------------------------

local keys = {}
keys.up = 200
keys.down = 208
keys.left = 203
keys.right = 205
keys.enter = 28

local function map(value, low, high, low_2, high_2)
    local relative_value = (value - low) / (high - low)
    local scaled_value = low_2 + (high_2 - low_2) * relative_value
    return scaled_value
end

local function startDrawer(code, gpu, posX, posY, sizeX, sizeY, state)
    local oldb = gpu.getBackground()
    local oldf = gpu.getForeground()
    code(gpu, posX, posY, sizeX, sizeY, state)
    gpu.setBackground(oldb)
    gpu.setForeground(oldf)
end

local function drawtext(gpu, color, posX, posY, text)
    local oldb = gpu.getBackground()
    local oldf = gpu.setForeground(color)
    local rx, ry = gpu.getResolution()
    for i = 1, unicode.len(text) do
        local char = unicode.sub(text, i, i)
        if posX + (i - 1) < 1 or posX + (i - 1) > rx then
            break
        end
        local _, _, nb = gpu.get(posX + (i - 1), posY)
        gpu.setBackground(nb)
        gpu.set(posX + (i - 1), posY, char)
    end
    gpu.setBackground(oldb)
    gpu.setForeground(oldf)
end

local function getClick(posX, posY, sizeX, sizeY, touchX, touchY)
    if touchX >= posX and touchX < (posX + sizeX) then
        if touchY >= posY and touchY < (posY + sizeY) then
            return true
        end
    end
end

local function getStandertOffColors(gpu)
    local depth = math.floor(gpu.getDepth())
    if depth == 1 then
        return 0x000000, 0xFFFFFF
    else
        return 0x666666, 0x444444
    end
end

local function touchIn(screen, posX, posY, button)
    event.push("touch", screen, posX, posY, button or 0)
end

local function blinkIn(gpu, posX, posY)
    local oldb = gpu.getBackground()
    local oldf = gpu.getForeground()
    local char, fore, back = gpu.get(posX, posY)

    gpu.setBackground(0xFFFFFF - back)
    gpu.setForeground(0xFFFFFF - fore)
    gpu.set(posX, posY, char)

    gpu.setBackground(oldb)
    gpu.setForeground(oldf)
end

--------------------------------------------

return {create = function(customX, customY, customGpu, customScreen, customKeyboard)
    local lib = {}
    lib.gpu = customGpu or term.gpu()
    lib.scenes = {}
    lib.selected = 1
    lib.screen = customScreen or term.screen()
    lib.keyboard = customKeyboard or term.keyboard()
    lib.closeallow = true
    lib.exitcallbacks = {}

    local oldScreen = lib.gpu.getScreen()
    if oldScreen ~= lib.screen then
        lib.gpu.bind(oldScreen)
    end
    local rx, ry = lib.gpu.getResolution()
    if customX and customY then
        lib.gpu.setResolution(customX, customY)
    end

    lib.exit = function(bool)
        if not lib.closeallow and bool then
            return
        end
        for i = 1, #lib.exitcallbacks do
            lib.exitcallbacks[i]()
        end
        if oldScreen then
            lib.gpu.bind(oldScreen)
        end
        lib.gpu.setResolution(rx, ry)
        term.clear()
        os.exit()
    end

    ------------------------------------------------

    lib.getScene = function(num)
        local number = num or lib.selected
        return lib.scenes[number]
    end

    lib.resetButtons = function()
        local objs = lib.getScene().objs
        for i = 1, #objs do
            local obj = objs[i]
            if obj.togle == false and obj.state ~= nil then
                obj.state = false
            end
        end
    end

    local oldtime = 0
    lib.interrupt = function(...)
        local name = ...
        if name == "interrupted" then
            lib.exit(true)
        end
        if lib.cursor then
            lib.cursor.insertEvent(...)
        end
    end

    lib.uploadEvent = function(...)
        lib.interrupt(...)
        lib.resetButtons()
        local scene = lib.getScene()
        for i2 = 1, #scene.objs do
            local obj = scene.objs[i2]
            if obj.insertEvent then
                obj.insertEvent(...)
            end
        end
    end

    lib.redraw = function()
        if lib.cursor then
            lib.cursor.num = 0
        end
        lib.getScene().draw()
    end

    lib.select = function(num)
        if type(num) ~= "number" then
            for i = 1, #lib.scenes do
                if lib.scenes[i] == num then
                    lib.selected = i
                    break
                end
            end
        else
            lib.selected = num
        end
        lib.redraw()
    end

    lib.createExitButtons = function(posX, posY)
        local x, y = lib.gpu.getResolution()
        if posX and posY then
            x = posX
            y = posY
        end
        for i = 1, #lib.scenes do
            lib.getScene(i).createExitButton(x, y)
        end
    end

    ------------------------------------------------

    lib.createCursor = function()
        local obj = {}
        obj.posX = 1
        obj.posY = 1
        blinkIn(lib.gpu, obj.posX, obj.posY)

        obj.draw = function()
        end

        local oldchar, oldfore, oldback
        obj.insertEvent = function(...)
            local eventName, keyboard, char, code = ...
            if eventName ~= "key_down" or keyboard ~= lib.keyboard then
                return
            end
            local rx, ry = lib.gpu.getResolution()
            if code == keys.enter then
                touchIn(lib.screen, obj.posX, obj.posY)
                return
            end
            local tx, ty = obj.posX, obj.posY
            if code == keys.up then
                ty = ty - 1
            elseif code == keys.down then
                ty = ty + 1
            elseif code == keys.left then
                tx = tx - 1
            elseif code == keys.right then
                tx = tx + 1
            else
                return
            end
            if ty < 1 then ty = 1 end
            if ty > ry then ty = ry end
            if tx < 1 then tx = 1 end
            if tx > rx then tx = rx end

            if oldchar and oldfore and oldback then
                local char, fore, back = lib.gpu.get(obj.posX, obj.posY)
                if oldchar ~= char or oldfore ~= fore or oldback ~= back then
                    blinkIn(lib.gpu, obj.posX, obj.posY)
                end
            end

            blinkIn(lib.gpu, obj.posX, obj.posY)
            obj.posX = tx
            obj.posY = ty
            blinkIn(lib.gpu, obj.posX, obj.posY)
            oldchar, oldfore, oldback = lib.gpu.get(obj.posX, obj.posY)
        end
        
        lib.cursor = obj
        return obj
    end
    if not component.proxy(lib.screen).setTouchModeInverted then
        lib.createCursor()
    end

    lib.useCursor = function(state)
        if state then
            if not lib.cursor then
                lib.cursor = lib.createCursor()
            end
        else
            lib.cursor = nil
        end
    end

    lib.createScene = function(color)
        local scene = {}
        scene.color = color or 0
        scene.objs = {}

        scene.draw = function()
            local rx, ry = lib.gpu.getResolution()
            if type(scene.color) == "number" then
                local oldb = lib.gpu.setBackground(scene.color)
                lib.gpu.fill(1, 1, rx, ry, " ")
                lib.gpu.setBackground(oldb)
            else
                startDrawer(scene.color, lib.gpu, 1, 1, rx, ry)
            end
            for i = 1, #scene.objs do
                scene.objs[i].draw()
            end
        end

        scene.createButton = function(posX, posY, sizeX, sizeY, text, back, fore, togle, state, back2, fore2, callback)
            local obj = {}
            obj.posX = posX
            obj.posY = posY
            obj.sizeX = sizeX
            obj.sizeY = sizeY
            obj.text = text or " "
            obj.back = back or 0xFFFFFF
            obj.fore = fore or 0x000000
            obj.togle = togle or false
            obj.state = state or false
            local standert1, standert2 = getStandertOffColors(lib.gpu)
            obj.back2 = back2 or standert1
            obj.fore2 = fore2 or standert2
            obj.callbacks = {callback}

            obj.draw = function()
                if lib.getScene() ~= scene then return end
                local function text(color)
                    drawtext(lib.gpu, color, (obj.posX + math.floor(obj.sizeX / 2)) - math.floor(unicode.len(obj.text) / 2), obj.posY + math.floor(obj.sizeY / 2), obj.text)
                end
                if obj.togle then
                    if type(obj.back) == "number" then
                        local oldb
                        if obj.state then
                            oldb = lib.gpu.setBackground(obj.back)
                        else
                            oldb = lib.gpu.setBackground(obj.back2)
                        end
                        lib.gpu.fill(obj.posX, obj.posY, obj.sizeX, obj.sizeY, " ")
                        lib.gpu.setBackground(oldb)
                    else
                        startDrawer(obj.back, lib.gpu, obj.posX, obj.posY, obj.sizeX, obj.sizeY, obj.state)
                    end
                    if obj.state then
                        text(obj.fore)
                    else
                        text(obj.fore2)
                    end
                else
                    if type(obj.back) == "number" then
                        local oldb = lib.gpu.setBackground(obj.back)
                        lib.gpu.fill(obj.posX, obj.posY, obj.sizeX, obj.sizeY, " ")
                        lib.gpu.setBackground(oldb)
                    else
                        startDrawer(obj.back, lib.gpu, obj.posX, obj.posY, obj.sizeX, obj.sizeY, true)
                    end
                    text(obj.fore)
                end
            end

            obj.insertEvent = function(...)
                local eventName, uuid, touchX, touchY, button = ...
                if eventName ~= "touch" or uuid ~= lib.screen or button ~= 0 then
                    return
                end
                local click = getClick(obj.posX, obj.posY, obj.sizeX, obj.sizeY, touchX, touchY)
                if not click then
                    return
                end
                if obj.togle then
                    obj.state = not obj.state
                    obj.draw()
                    for i = 1, #obj.callbacks do
                        obj.callbacks[i](obj.state)
                    end
                else
                    obj.state = true
                    for i = 1, #obj.callbacks do
                        obj.callbacks[i]()
                    end
                end
            end

            obj.getState = function()
                local out = obj.state
                if not obj.togle then
                    obj.state = false
                end
                return out
            end

            scene.objs[#scene.objs + 1] = obj
            return obj
        end

        scene.createLabel = function(posX, posY, sizeX, sizeY, text, back, fore)
            local obj = {}
            obj.posX = posX
            obj.posY = posY
            obj.sizeX = sizeX
            obj.sizeY = sizeY
            obj.text = text or " "
            obj.back = back or 0xFFFFFF
            obj.fore = fore or 0x000000
    
            obj.draw = function()
                if lib.getScene() ~= scene then return end
                local function text(color)
                    drawtext(lib.gpu, color, (obj.posX + math.floor(obj.sizeX / 2)) - math.floor(unicode.len(obj.text) / 2), obj.posY + math.floor(obj.sizeY / 2), obj.text)
                end
                if type(obj.back) == "number" then
                    local oldb = lib.gpu.setBackground(obj.back)
                    lib.gpu.fill(obj.posX, obj.posY, obj.sizeX, obj.sizeY, " ")
                    lib.gpu.setBackground(oldb)
                else
                    startDrawer(obj.back, lib.gpu, obj.posX, obj.posY, obj.sizeX, obj.sizeY, true)
                end
                text(obj.fore)
            end

            scene.objs[#scene.objs + 1] = obj
            return obj
        end

        scene.createExitButton = function(posX, posY)
            local col = 0xFFFFFF
            if math.floor(lib.gpu.getDepth()) == 1 then
                col = 0
            end
            scene.createButton(posX, posY, 1, 1, "X", 0xFF0000, col, nil, nil, nil, nil, lib.exit)
        end

        scene.createSeekBar = function(posX, posY, sizeX, back, fore, min, max, value, touch, mode, callback)
            local obj = {}
            obj.posX = posX
            obj.posY = posY
            obj.sizeX = sizeX
            obj.back = back or 0xFFFFFF
            obj.fore = fore or 0x000000
            obj.min = min or 0
            obj.max = max or 1
            obj.touch = touch or true
            obj.mode = mode or 0
            obj.callbacks = {callback}
            if obj.mode ~= 2 then
                obj.value = map(value or 0, obj.min, obj.max, 0, obj.sizeX - 1)
            else
                obj.value = map(value or 0, obj.max, obj.min, 0, obj.sizeX - 1)
            end

            obj.draw = function()
                if lib.getScene() ~= scene then return end
                local oldb = lib.gpu.setBackground(obj.back)
                local oldf = lib.gpu.setForeground(obj.fore)

                if obj.mode == 0 then
                    lib.gpu.fill(obj.posX, obj.posY, obj.sizeX, 1, " ")
                    lib.gpu.set(obj.posX + obj.value, obj.posY, "#")
                elseif obj.mode == 1 or obj.mode == 2 then
                    lib.gpu.fill(obj.posX, obj.posY, 1, obj.sizeX, " ")
                    lib.gpu.set(obj.posX, (obj.posY + (obj.sizeX - 1)) - obj.value, "#")
                end

                lib.gpu.setBackground(oldb)
                lib.gpu.setForeground(oldf)
            end

            obj.getState = function()
                if obj.mode ~= 2 then
                    return map(obj.value, 0, obj.sizeX - 1, obj.min, obj.max)
                else
                    return map(obj.value, 0, obj.sizeX - 1, obj.max, obj.min)
                end
            end

            obj.setState = function(new)
                local old = obj.getState()
                if obj.mode ~= 2 then
                    obj.value = map(new, obj.min, obj.max, 0, obj.sizeX - 1)
                else
                    obj.value = map(new, obj.max, obj.min, 0, obj.sizeX - 1)
                end
                obj.draw()
                return old
            end

            obj.getValue = function()
                if obj.mode ~= 2 then
                    return obj.value
                else
                    return map(obj.value, 0, obj.sizeX - 1, obj.sizeX - 1, 0)
                end
            end

            obj.setValue = function(new)
                if not new or new < 0 or new > obj.sizeX - 1 then
                    return nil
                end
                local old = obj.value
                if obj.mode ~= 2 then
                    obj.value = new
                else
                    obj.value = map(new, 0, obj.sizeX - 1, obj.sizeX - 1, 0)
                end
                obj.draw()
                return old
            end

            obj.insertEvent = function(...)
                local eventName, uuid, touchX, touchY, button = ...
                if (eventName ~= "touch" and eventName ~= "drag") or uuid ~= lib.screen or button ~= 0 or not obj.touch then
                    return
                end
                local oldv = obj.getState()
                if (touchY == obj.posY and obj.mode == 0) or (touchX == obj.posX and (obj.mode == 1 or obj.mode == 2)) then
                    if (touchX >= obj.posX and touchX < (obj.posX + obj.sizeX) and obj.mode == 0) or (touchY >= obj.posY and touchY < (obj.posY + obj.sizeX) and (obj.mode == 1 or obj.mode == 2)) then
                        local value
                        if obj.mode == 0 then
                            value = (touchX - (obj.posX - 1)) - 1
                        elseif obj.mode == 1 or obj.mode == 2 then
                            value = obj.sizeX - (touchY - (obj.posY - 1))
                        end
                        obj.value = value
                        obj.draw()
                        for i = 1, #obj.callbacks do
                            obj.callbacks[i](obj.getState(), oldv)
                        end
                    end
                end
            end

            scene.objs[#scene.objs + 1] = obj
            return obj
        end

        scene.createLogZone = function(posX, posY, sizeX, sizeY, back, fore, seek_back, seek_fore, autoscroll)
            local obj = {}
            obj.posX = posX
            obj.posY = posY
            obj.sizeX = sizeX - 1
            obj.sizeY = sizeY
            obj.back = back or 0xFFFFFF
            obj.fore = fore or 0x000000
            obj.seek_back = seek_back or 0xFFFFFF
            obj.seek_fore = seek_fore or 0x000000
            obj.seekvalue = 0
            obj.datalist = {}
            obj.maxstrs = obj.sizeY * (obj.sizeY / 2)
            obj.autoscroll = autoscroll or true
            local function drawData()
                obj.draw()
            end
            obj.seekbar = scene.createSeekBar((posX + sizeX) - 1, posY, sizeY, seek_back, seek_fore, 1, #obj.datalist, 1, true, 2, drawData)

            obj.draw = function()
                if lib.getScene() ~= scene then return end
                local oldb = lib.gpu.setBackground(obj.back)
                local oldf = lib.gpu.setForeground(obj.fore)
                lib.gpu.fill(obj.posX, obj.posY, obj.sizeX, obj.sizeY, " ")
                obj.seekbar.draw()
                for i = 1, #obj.datalist do
                    local select = (math.floor(obj.seekbar.getState()) + 1) - i
                    if select > 0 and select <= #obj.datalist then
                        local data = obj.datalist[select]
                        local posY = (obj.posY + obj.sizeY) - i
                        if posY >= obj.posY then
                            lib.gpu.set(obj.posX, posY, data)
                        else
                            return
                        end
                    else
                        return
                    end
                end
                lib.gpu.setBackground(oldb)
                lib.gpu.setForeground(oldf)
            end

            obj.clearOld = function()
                for i = 1, #obj.datalist do
                    obj.datalist[i] = obj.datalist[i + 1]
                end
            end

            obj.clear = function()
                obj.datalist = {}
                obj.seekbar.max = #obj.datalist
                obj.seekbar.setValue(sizeY)
            end

            obj.add = function(str)
                obj.datalist[#obj.datalist + 1] = str
                while #obj.datalist > obj.maxstrs do
                    obj.clearOld()
                end
                obj.seekbar.max = #obj.datalist
                if obj.autoscroll then obj.seekbar.setValue(obj.sizeY - 1) end
                obj.draw()
            end

            obj.setpos = function(num)
                obj.seekbar.setState(num)
            end

            obj.insertEvent = function(...)
                local eventName, uuid, touchX, touchY, value = ...
                if eventName ~= "scroll" or uuid ~= lib.screen then
                    return
                end
                if touchX >= obj.posX and touchX < (obj.posX + obj.sizeX) then
                    if touchY >= obj.posY and touchY < (obj.posY + obj.sizeY) then
                        obj.seekbar.setValue(obj.seekbar.getValue() - value)
                        obj.draw()
                    end
                end
            end

            scene.objs[#scene.objs + 1] = obj
            return obj
        end

        scene.createInputBox = function(posX, posY, sizeX, sizeY, text, back, fore, callback)
            local obj = {}
            obj.posX = posX
            obj.posY = posY
            obj.sizeX = sizeX
            obj.sizeY = sizeY
            obj.text = text
            obj.back = back or 0xFFFFFF
            obj.fore = fore or 0x000000
            obj.value = ""
            obj.wail = false
            obj.callbacks = {callback}
            local function input()
                if obj.wail then
                    return
                end
                obj.wail = true
                local text = obj.button.text
                obj.button.text = ""
                obj.button.draw()

                local function read()
                    term.setCursor(obj.posX, obj.posY + math.floor(obj.sizeY / 2))

                    local out = io.read()
                    obj.value = out

                    obj.button.text = text
                    obj.wail = false
                    obj.button.draw()

                    lib.redraw()

                    for i = 1, #obj.callbacks do
                        obj.callbacks[i](obj.value)
                    end
                end
                thread.create(read)
            end

            obj.button = scene.createButton(obj.posX, obj.posY, obj.sizeX, obj.sizeY, obj.text, obj.back, obj.fore, nil, nil, nil, nil, input)

            obj.get = function() return obj.value end
            obj.input = input
            obj.draw = function() end

            scene.objs[#scene.objs + 1] = obj
            return obj
        end

        scene.createDrawZone = function(posX, posY, sizeX, sizeY, image, index)
            local obj = {}
            obj.posX = posX
            obj.posY = posY
            obj.sizeX = sizeX
            obj.sizeY = sizeY
            obj.image = image
            obj.index = index or 0
    
            obj.draw = function()
                if lib.getScene() ~= scene then return end
                startDrawer(obj.image, lib.gpu, obj.posX, obj.posY, obj.sizeX, obj.sizeY, true)
            end

            obj.insertEvent = function(...)
                local eventName, uuid, touchX, touchY, button = ...
                if eventName ~= "touch" or uuid ~= lib.screen then
                    return
                end
                local lx, ly = 0, 0
                if touchX >= obj.posX and touchX < obj.posX + obj.sizeX then
                    if touchY >= obj.posY and touchY < obj.posY + obj.sizeY then
                        lx = (touchX - obj.posX) + 1
                        ly = (touchY - obj.posY) + 1
                        event.push("touchInDraw", obj.index, lx, ly, button)
                    end
                end
            end

            scene.objs[#scene.objs + 1] = obj
            return obj
        end

        lib.scenes[#lib.scenes + 1] = scene
        return scene
    end

    lib.context = function(skip, posX, posY, datain)
        local data = {}
        if type(datain[1]) ~= "table" then
            for i = 1, #datain do
                data[i] = {datain[i], true}
            end
        else
            data = datain
        end
        local texts = {}
        local activates = {}
        
        local sizeX = 0
        local sizeY = #data
    
        for i = 1, #data do
            local dat = data[i]
            texts[i] = dat[1]
            activates[i] = dat[2]
            if unicode.len(dat[1]) > sizeX then
                sizeX = unicode.len(dat[1])
            end
        end
    
        local gpu = lib.gpu
        local depth = lib.gpu.getDepth()
    
        local oldb = gpu.getBackground()
        local oldf = gpu.getForeground()
        
        if math.floor(gpu.getDepth()) ~= 1 then
            gpu.setBackground(0x444444)
            gpu.fill(posX + 1, posY + 1, sizeX, sizeY, " ")
        end
    
        gpu.setBackground(0xFFFFFF)
        gpu.fill(posX, posY, sizeX, sizeY, " ")
    
        for i = 1, sizeY do
            local text = texts[i]
            local activate = activates[i]
            if math.floor(gpu.getDepth()) ~= 1 then
                if activate then
                    gpu.setForeground(0x000000)
                else
                    gpu.setForeground(0x666666)
                end
            else
                if activate then
                    gpu.setForeground(0x000000)
                    gpu.setBackground(0xFFFFFF)
                else
                    gpu.setForeground(0xFFFFFF)
                    gpu.setBackground(0x000000)
                end
            end
            gpu.set(posX, posY + (i - 1), text)
        end
    
        local out
        while true do
            lib.count = 0
            local tab = {event.pull(0.3)}
            local eventName, uuid, x, y, button = table.unpack(tab or {})
            lib.interrupt(table.unpack(tab or {}))
            if eventName == "touch" and uuid == lib.screen and button == 0 then
                if button ~= 0 and skip then
                    break
                end
                if button == 0 then
                    if x >= posX and x <= ((posX + sizeX) - 1) then
                        local index = y - (posY - 1)
                        if index < 1 or index > #texts then
                            if skip then
                                break
                            end
                        else
                            if activates[index] then
                                out = index
                                break
                            end
                        end
                    elseif skip then
                        break
                    end
                end
            end
        end

        lib.redraw()
    
        gpu.setBackground(oldb)
        gpu.setForeground(oldf)
    
        return texts[out], out
    end

    function lib.yesno(text)
        local gpu = lib.gpu
        local depth = gpu.getDepth()
        local rx, ry = gpu.getResolution()
    
        local color1 = 0xFF0000
        local color2 = 0x00FF00
    
        if math.floor(depth) == 1 then
            color1 = 0x0
            color2 = 0x0
        end
    
        local gui = lib.createScene(0xFFFFFF)
        gui.createLabel(1, 1, rx, 1, text)
        local yes = gui.createButton(1, 2, rx, 3, "yes", color2, 0xffffff)
        local no = gui.createButton(1, 6, rx, 3, "no", color1, 0xffffff)
        
        local oldselect = lib.selected
        lib.select(gui)
    
        local out
        while true do
            lib.count = 0
            local eventData = {event.pull(0.3)}
            lib.interrupt(table.unpack(eventData or {}))
            if eventData[1] == "touch" and eventData[2] == lib.screen and eventData[5] == 0 then
                lib.uploadEvent(table.unpack(eventData))
                if yes.getState() then
                    out = true
                    break
                elseif no.getState() then
                    out = false
                    break
                end
            end
        end

        lib.scenes[lib.selected] = nil
        lib.select(oldselect)
    
        return out
    end
    
    lib.splas = function(text)
        local gpu = lib.gpu
        local depth = gpu.getDepth()
        local rx, ry = gpu.getResolution()
    
        local color = 0x0000FF
        if math.floor(depth) == 1 then
            color = 0x0
        end
    
        local gui = lib.createScene(0xFFFFFF)
        gui.createLabel(1, 1, rx, 1, text)
        local ok = gui.createButton(1, 2, rx, 3, "ok", color, 0xffffff)

        local oldselect = lib.selected
        lib.select(gui)
    
        while true do
            lib.count = 0
            local eventData = {event.pull(0.3)}
            lib.interrupt(table.unpack(eventData or {}))
            if eventData[1] == "touch" and eventData[2] == lib.screen and eventData[5] == 0 then
                lib.uploadEvent(table.unpack(eventData))
                if ok.getState() then
                    break
                end
            end
        end

        lib.scenes[lib.selected] = nil
        lib.select(oldselect)
    end

    return lib
end}