local fs = require("filesystem")
local computer = require("computer")
local unicode = require("unicode")
local term = require("term")
local process = require("process")
local component = require("component")

---------------------------------------

local lib = {}

lib.tracepath = function(path)
    fs.makeDirectory(path)
end

lib.getFile = function(path)
    local file, err = io.open(path, "rb")
    if not file then return nil, err end
    local data = file:read("*a")
    file:close()
    return data
end

lib.saveFile = function(path, data)
    lib.tracepath(fs.path(path))
    local file, err = io.open(path, "wb")
    if not file then return nil, err end
    file:write(data)
    file:close()
    return true
end

lib.generateRandomID = function(size)
    local size = size or 16
    local data = ""
    for i = 1, size do
        data = data..tostring(math.floor(math.random(0, 9)))
    end
    return data
end

lib.inTable = function(tab, datain)
    for _, data in pairs(tab) do
        if data == datain then
            return true
        end
    end
    return false
end
-- оказываеться сохнанив значения как tab.value к нему молжно обратиться как tab["value"] я этого не знал по эмоту гародилл кастыли
lib.getTab = function(tab, str) 
     return load("return tab."..str, "=stdin", nil, {tab = tab})()
end

lib.setTab = function(tab, str, value)
    load("tab."..str.." = value", "=stdin", nil, {tab = tab, value = value})()
end

lib.interruptCheck = function(code, call)
    local ok, err = xpcall(code, debug.traceback)
    call()
    if not ok then
        err = err or "unkown error"
        local target = "interrupted"
        if not err:sub(1, #target) == target then
            local term = require("term")
            if term.isAvailable() then
                local gpu = term.gpu()
                local oldb = gpu.setBackground(0x000000)
                local oldf = gpu.setForeground(0xFF0000)
                print(err)
                gpu.setBackground(oldb)
                gpu.setForeground(oldf)
            end
        end
    end
end

lib.loadconfig = function(path)
    local env = {}
    pcall(loadfile(path, "t", env))
    return env
end

lib.saveconfig = function(path, tab)
    local str = ""
    for key, value in pairs(tab) do
        str = str..key.." = \""..tostring(value).."\"\n"
    end
    lib.saveFile(path, str)
end

lib.isOnline = function(nikname)
    local ok, err = computer.addUser(nikname)
    if not ok and err == "player must be online" then
        return false
    elseif ok then
        computer.removeUser(nikname)
        return true
    elseif not ok and err == "user exists" then
        computer.removeUser(nikname)
        local ok, err = computer.addUser(nikname)
        --спрашиваеться как в такой ситуации добавь игрока обратно если он не онлайн
    end
end

lib.modProgramm = function(str)
    return str
    --return "local function mainchunk(...) "..str.."\nend\nlocal out = {mainchunk(...)}\nos.exit()\nreturn table.unpack(out)"
end

lib.split = function(str, sep)
    local parts, count = {}, 1
    local i = 1
    while true do
        if i > #str then break end
        local char = str:sub(i, #sep + (i - 1))
        if not parts[count] then parts[count] = "" end
        if char == sep then
            count = count + 1
            i = i + #sep
        else
            parts[count] = parts[count] .. str:sub(i, i)
            i = i + 1
        end
    end
    if str:sub(#str - (#sep - 1), #str) == sep then table.insert(parts, "") end
    return parts
end

lib.splitText = function(str, sep)
    local parts, count = {}, 1
    local i = 1
    while true do
        if i > unicode.len(str) then break end
        local char = unicode.sub(str, i, unicode.len(sep) + (i - 1))
        if not parts[count] then parts[count] = "" end
        if char == sep then
            count = count + 1
            i = i + unicode.len(sep)
        else
            parts[count] = parts[count] .. unicode.sub(str, i, i)
            i = i + 1
        end
    end
    if unicode.sub(str, unicode.len(str) - (unicode.len(sep) - 1), unicode.len(str)) == sep then table.insert(parts, "") end
    return parts
end

lib.saveGpu = function(gpuAddress)
    local gpu
    if gpuAddress then
        gpu = component.proxy(gpuAddress)
    else
        gpu = term.gpu()
    end
    local vx, vy = gpu.getViewport()
    local rx, ry = gpu.getResolution()
    local back, isPalB = gpu.getBackground()
    local fore, isPalF = gpu.getForeground()
    local screen = gpu.getScreen()
    local depth = gpu.getDepth()

    return function()
        if screen and gpu.getScreen() ~= screen then gpu.bind(screen, false) end
        gpu.setResolution(rx, ry)
        gpu.setViewport(vx, vy)
        gpu.setDepth(depth)
        gpu.setBackground(back, isPalB)
        gpu.setForeground(fore, isPalF)
    end
end

function lib.reconnectGpu(gpuAddress, screen, reset)
    local gpu
    if gpuAddress then
        gpu = component.proxy(gpuAddress)
    else
        gpu = term.gpu()
    end
    local reset1 = lib.saveGpu(gpuAddress)
    local oldScreen = gpu.getScreen()
    gpu.bind(screen, reset)
    
    return function()
        if oldScreen and gpu.getScreen() ~= oldScreen then gpu.bind(oldScreen, false) end
        reset1()
    end
end

function lib.toParts(str, max)
    local strs = {}
    local temp = ""
    for i = 1, #str do
        local char = str:sub(i, i)
        temp = temp .. char
        if #temp >= max then
            table.insert(strs, temp)
            temp = ""
        end
    end
    table.insert(strs, temp)
    return strs
end

function lib.simpleTableClone(tbl)
    local newtbl = {}
    for k, v in pairs(tbl) do
        newtbl[k] = v
    end
    return newtbl
end

function lib.unpack(tbl, tstart, tend)
    local size = 0
    for key, value in pairs(tbl) do
        if type(key) == "number" then
            if key > size then size = key end
        end
    end

    if not tstart then tstart = 1 end
    if not tend then tend = size end

    local code = "return "

    for i = tstart, tend do
        --local i2 = (i - tstart) + 1
        if i == tend then
            code = code .. "t[" .. tostring(i) .. "]"
        else
            code = code .. "t[" .. tostring(i) .. "], "
        end
    end

    return assert(load(code, "=data", nil, {t = tbl}))()
end

function lib.tableLen(tbl)
    local count = 0
    for k, v in pairs(tbl) do
        count = count + 1
    end
    return count
end

function lib.indexTableLen(tbl)
    local size = 0
    for key, value in pairs(tbl) do
        if type(key) == "number" then
            if key > size then size = key end
        end
    end
    return size
end

function lib.execute(_ENV, path, ...)
    local file, err = lib.getFile(path)
    if not file then return nil, err end
    file = lib.modProgramm(file)
    local func, err = load(file, path, nil, _ENV)
    if not func then return nil, err end

    local killFunc = process.info().data.signal
    process.info().data.signal = function() error("interrupted") end
    os.setenv("_", path)
    local out = {xpcall(func, debug.traceback, ...)}
    process.info().data.signal = killFunc

    return table.unpack(out)
end

function lib.map(value, low, high, low_2, high_2)
    local relative_value = (value - low) / (high - low)
    local scaled_value = low_2 + (high_2 - low_2) * relative_value
    return scaled_value
end

function lib.constrain(value, min, max)
    return math.min(math.max(value, min), max)
end

function lib.mapClip(value, low, high, low_2, high_2)
    return lib.constrain(lib.map(value, low, high, low_2, high_2), low_2, high_2)
end

function lib.selectColor(gpu, mainColor, miniColor, bw)
    local depth = math.floor(gpu.getDepth())
    if not miniColor then miniColor = mainColor end
    if depth == 4 then
        return miniColor
    elseif depth == 1 then
        return bw and 0xFFFFFF or 0x000000
    end
    return mainColor
end

function lib.xor(...)
    local dat = {...}
    local state = false
    for i = 1, #dat do
        if dat[i] then
            state = not state
        end
    end
    return state
end

function lib.floorAt(value, subValue)
    return math.floor(value // subValue) * subValue
end

function lib.logTo(path, text)
    lib.tracepath(fs.path(path))
    local file, err = io.open(path, "ab")
    if not file then return nil, err end
    file:write(text .. "\n")
    file:close()
    return true
end

function lib.getInternetFile(url)
    local handle, data, result, reason = component.internet.request(url), ""
    if handle then
        while true do
            result, reason = handle.read(math.huge) 
            if result then
                data = data .. result
            else
                handle.close()
                
                if reason then
                    return nil, reason
                else
                    return data
                end
            end
        end
    else
        return nil, "unvalid address"
    end
end

function lib.isInternet()
    return component.isAvailable("internet") and pcall(function(url) assert(lib.getInternetFile(url)) end, "https://raw.githubusercontent.com/igorkll/openOSpath/main/null")
end

return lib