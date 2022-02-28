local fs = require("filesystem")
local computer = require("computer")
local unicode = require("unicode")

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
    return "local function mainchunk(...) "..str.."\nend\nlocal out = {mainchunk(...)}\nos.exit()\nreturn table.unpack(out)"
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

return lib