apis.setBootAddress = function(address) apis.savefile(apis.addresscfgpath, address) end
apis.getBootAddress = function() local data = apis.getfile(apis.addresscfgpath) return data or "" end

apis.setBootloaderName = function(name) apis.savefile(apis.bootloadercfgpath, name) end
apis.getBootloaderName = function() local data = apis.getfile(apis.bootloadercfgpath) return data or "" end

apis.setBiosPassword = function(name) apis.savefile(apis.biospasswordcfgpath, name) end
apis.getBiosPassword = function() local data = apis.getfile(apis.biospasswordcfgpath) return data or "" end

apis.setBootPasswordState = function(state)
    if state then
        apis.savefile(apis.bootpasswordcfgpath, "")
    else
        apis.fs.remove(apis.bootpasswordcfgpath)
    end
end
apis.getBootPasswordState = function() return apis.fs.exists(apis.bootpasswordcfgpath) end

apis.isPassword = function() return apis.fs.exists(apis.biospasswordcfgpath) end
apis.removePassword = function() apis.fs.remove(apis.biospasswordcfgpath) apis.fs.remove(apis.bootpasswordcfgpath) end

apis.setConfigResolution = function(aspectRatio, rx, ry)
    rx = math.floor(rx)
    ry = math.floor(ry)
    if aspectRatio then
        apis.savefile(apis.resolutionAspectRatioMode, "")
    else
        apis.fs.remove(apis.resolutionAspectRatioMode)
    end
    apis.savefile(apis.biosresolutioncfgpath, tostring(rx).."\n"..tostring(ry))
end

apis.setBiosKey = function(name) apis.savefile(apis.keypath, name) end
apis.getBiosKey = function() local data = apis.getfile(apis.keypath) return data or "" end

if not apis.fs.exists(apis.servicecodepath) then
    apis.savefile(apis.servicecodepath, tostring(math.floor(math.random(1, 99999999))))
end
apis.getServiceCode = function() local data = apis.getfile(apis.servicecodepath) return data or "" end

apis.saveTheme = function()
    apis.savefile(apis.themepath, tostring(apis.back).."\n"..tostring(apis.fore))
end

do
    local gpu = component.list("gpu")()
    local screen = component.list("screen")()
    if gpu and screen then
        gpu = component.proxy(gpu)
        gpu.bind(screen)

        apis.gpu = gpu
        apis.screen = component.proxy(screen)
        apis.keyboard = apis.screen.getKeyboards()[1]
        apis.gpuexists = true
        if apis.screen.setTouchModeInverted then
            apis.touch = true
        end
    else
        local tab = {}
        local metatable = {__index = function() error("gpu and screen are required") end}
        setmetatable(tab, metatable)

        apis.gpu = tab
        apis.screen = tab
    end
end

function apis.boot(data)
    if type(data) ~= "string" then
        error("input type err, type "..type(data))
    end

    apis = nil
    local error = error
    local load = load
    local xpcall = xpcall
    local traceback = debug.traceback
    
    local code, err = load(data, "=init")
    if not code then
        error("system load err: "..(err or "unkown"))
    end
    local ok, err = xpcall(code, traceback)
    if not ok then
        error("system run err: "..(err or "unkown"))
    else
        error("system halted")
    end
end

function apis.wait()
    while true do
        local eventName, uuid, _, data = computer.pullSignal()
        if (eventName == "key_down" and data == 28 and apis.keyboard == uuid) or (apis.screen and eventName == "touch" and apis.screen.address == uuid) then
            return
        end
    end
end

function apis.setText(text, posY)
    local gpu = apis.gpu
    local rx, ry = gpu.getResolution()
    gpu.set(math.floor((rx / 2) - (unicode.len(text) / 2)) + 1, posY, text)
end

function apis.recolors()
    local gpu = apis.gpu
    local back = gpu.getBackground()
    local fore = gpu.getForeground()
    gpu.setBackground(fore)
    gpu.setForeground(back)
end

function apis.view(splash)
    local gpu = apis.gpu
    local rx, ry = gpu.getResolution()

    local oldb = gpu.setBackground(apis.back)
    local oldf = gpu.setForeground(apis.fore)

    gpu.fill(1, 1, rx, ry, " ")
    local posY = 1
    for subsplash in splash:gmatch("[^\n]+") do
        for i = 1, unicode.len(subsplash) do
            local char = unicode.sub(subsplash, i, i)
            if string.byte(char) < 32 then
                char = " "
            end
            gpu.set(i, posY, char)
        end
        posY = posY + 1
        if posY > ry then
            break
        end
    end

    gpu.setBackground(oldb)
    gpu.setForeground(oldf)
end

function apis.splash(splash)
    splash = splash .. "\npress enter to continue..."
    apis.view(splash)
    apis.wait()
end

function apis.select(selecters, pos)
    local gpu = apis.gpu
    local rx, ry = gpu.getResolution()
    local menupos = (pos or 1) + 1

    local oldb = gpu.setBackground(apis.back)
    local oldf = gpu.setForeground(apis.fore)

    local selected = menupos
    
    while true do
        gpu.fill(1, 1, rx, ry, " ")

        local drawcount = 1
        local startpos = (math.floor((selected - 1) / ry) * ry) + 1
        for i = startpos, #selecters do
            if drawcount > ry then
                break
            end
            
            if i == selected or i == 1 then
                apis.recolors()
            end
            apis.setText(selecters[i], drawcount)
            if i == selected or i == 1 then
                apis.recolors()
            end

            drawcount = drawcount + 1
        end

        local eventName, uuid, _, data, data2 = computer.pullSignal()
        if eventName == "key_down" and uuid == apis.keyboard then
            if data == 200 then
                if selected > 2 then
                    selected = selected - 1
                end
            elseif data == 208 then
                if selected < #selecters then
                    selected = selected + 1
                end
            elseif data == 28 then
                return selected - 1
            end
        elseif eventName == "touch" and uuid == apis.screen.address then
            if data > 1 and data <= #selecters + 1 then
                return data - 1
            end
        elseif eventName == "scroll" and uuid == apis.screen.address then
            if data2 == -1 then
                if selected < #selecters then
                    selected = selected + 1
                end
            else
                if selected > 2 then
                    selected = selected - 1
                end
            end
        end
    end

    gpu.setBackground(oldb)
    gpu.setForeground(oldf)
end

function apis.setColor()
    local gpu = apis.gpu

    local oldb = gpu.setBackground(apis.back)
    local oldf = gpu.setForeground(apis.fore)
    
    return {back = function() gpu.setBackground(oldb) gpu.setForeground(oldf) end}
end

function apis.input(posX, posY)
    if not apis.keyboard then
        error("required keyboard input")
    end
    local colorObj = apis.setColor()
    local term = {posX = posX, posY = posY, keyboard = apis.keyboard}
    local gpu = apis.gpu
    local buffer = ""
    while true do
        gpu.set(term.posX, term.posY, "_")
        local eventName, uuid, char, code = computer.pullSignal()
        if eventName == "key_down" and uuid == term.keyboard then
            if code == 28 then
                colorObj.back()
                return buffer
            elseif code == 14 then
                if unicode.len(buffer) > 0 then
                    buffer = unicode.sub(buffer, 1, unicode.len(buffer) - 1)
                    gpu.set(term.posX, term.posY, " ")
                    term.posX = term.posX - 1
                    gpu.set(term.posX, term.posY, " ")
                end
            elseif char ~= 0 then
                buffer = buffer .. unicode.char(char)
                gpu.set(term.posX, term.posY, unicode.char(char))
                term.posX = term.posX + 1
            end
        elseif eventName == "clipboard" and uuid == term.keyboard then
            buffer = buffer .. char
            gpu.set(term.posX, term.posY, char)
            term.posX = term.posX + unicode.len(char)
            if unicode.sub(char, unicode.len(char), unicode.len(char)) == "\n" then
                return unicode.sub(buffer, 1, unicode.len(buffer) - 1)
            end
        end
    end
end

function apis.clear()
    local gpu = apis.gpu
    local rx, ry = gpu.getResolution()

    local oldb = gpu.setBackground(apis.back)
    local oldf = gpu.setForeground(apis.fore)

    gpu.fill(1, 1, rx, ry, " ")

    gpu.setBackground(oldb)
    gpu.setForeground(oldf)
end

function apis.enterPassword(message)
    if not apis.isPassword() then
        return true
    end
    if not message then
        message = ""
    else
        message = message..": "
    end
    local objColor = apis.setColor()
    apis.clear()
    apis.gpu.set(1, 1, message.."ENTER PASSWORD: ")
    local input = apis.input(1, 2)
    objColor.back()
    if input == apis.getBiosPassword() then
        return true
    end
    return false
end

function apis.inputScreen(message)
    apis.clear()
    local colorObj = apis.setColor()
    apis.setText(message, 1)
    local input = apis.input(1, 2)
    colorObj.back()
    return input
end

function apis.yesno(label)
    local select = apis.select({label, "no", "no", "no", "no", "yes", "no", "no"})
    if select == 5 then
        return true
    end
    return false
end

--------------------------------------

if apis.gpuexists and apis.fs.exists(apis.themepath) then
    local config = apis.getfile(apis.themepath)
    local values = {}
    for data in config:gmatch("[^\n]+") do
        values[#values + 1] = data
    end
    if tonumber(values[1]) and tonumber(values[2]) then
        apis.back = tonumber(values[1])
        apis.fore = tonumber(values[2])
    end
end

function apis.setResolution()
    if apis.gpuexists then
        local mainx, mainy = apis.gpu.maxResolution()
        apis.rx = mainx
        apis.ry = mainy
        if apis.fs.exists(apis.biosresolutioncfgpath) then
            local data = apis.getfile(apis.biosresolutioncfgpath)
            if data then
                local values = {}
                for data in data:gmatch("[^\n]+") do
                    values[#values + 1] = data
                end
                local rx, ry = table.unpack(values)
                rx = tonumber(rx)
                ry = tonumber(ry)
                if apis.fs.exists(apis.resolutionAspectRatioMode) then
                    --да говнакод но я устал кароч таким образо значения гарантировано будет больше разрешения видюхи и при уменьшении до максимально допустимого бла бла бля кароч и так все понятно
                    rx = rx * mainx * 2
                    ry = ry * mainx
                end
                if rx and ry then
                    apis.rx = rx
                    apis.ry = ry
                else
                    apis.splash(apis.biosresolutioncfgpath.."\ncfg err: not value")
                end
            else
                apis.splash(apis.biosresolutioncfgpath.."\ncfg err: not data")
            end
        end
        while not pcall(apis.gpu.setResolution, apis.rx, apis.ry) do
            apis.rx = math.floor(apis.rx / 1.2)
            apis.ry = math.floor(apis.ry / 1.2)
        end
    end
end
apis.setResolution()