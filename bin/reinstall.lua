local component = require("component")
local su = require("superUtiles")
local fs = require("filesystem")
local computer = require("computer")

if not su.isInternet() then
    io.stderr:write("internet error")
    return
end

if not su.isRealInternet() then
    print("интернет карта подключена по сети, невозможно произвести переустоновку ос")
    if component.isAvailable("tablet") then
        print("вы можете устоновить планшет в зарядку подключеную к компьютеру и переустоновить ос с него используя recoverytool")
    else
        print("вы можете устоновить жеский диск усторойста в другой компьютер и переустоновить ос с него используя recoverytool")
    end
    return
end

if getEnergyPercentages() < 80 then
    io.stderr:write("для переустоновки ос необходим заряд не мения 80%\n")
    io.stderr:write("у вас " .. tostring(getEnergyPercentages()) .. "%\n")
    return
end

print("вас превествует программу переустоновки openOSmod")
print("переустоновливать ос рекомендуеться каждые 5 обновлений")
print("свои данные можно временно переложить на внешний диск")
io.write("вы уверены переустоновить openOSmod? ВСЕ ДАННЫЕ БУДУТ УТЕРЕНЫ [Y/n] ")
local read = io.read()
if read ~= "y" and read ~= "Y" then os.exit() end

local repo = assert(su.getTable("/etc/system.cfg")).updateRepo

--------------------------------------------------

fs.get("/").remove("/")
su.saveFile("/init.lua", "local repo = \"" .. repo .. "\"\n" .. [[
local internet = component.proxy(component.list("internet")() or error("internet card is not found", 0))
local fs = component.proxy(computer.getBootAddress())

local status
if statusAllow then
    status = _G.status
elseif smartEfi then
    status = function(msg)
        _G.status(msg, -1)
    end
else
    status = function()
    end
end

local function getInternetFile(url)
    local handle, data, result, reason = internet.request(url), ""
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

local function split(str, sep)
    local parts, count, i = {}, 1, 1
    while 1 do
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

local oldtime = -math.huge
local function interrupt()
    local uptime = computer.uptime()
    if uptime - oldtime > 3 then
        oldtime = uptime
        computer.pullSignal(0.1)
    end
end

local function segments(path)
    local parts = {}
    for part in path:gmatch("[^\\/]+") do
        local current, up = part:find("^%.?%.$")
        if current then
            if up == 2 then
                table.remove(parts)
            end
        else
            table.insert(parts, part)
        end
    end
    return parts
end

local function fs_path(path)
    local parts = segments(path)
    local result = table.concat(parts, "/", 1, #parts - 1) .. "/"
    if unicode.sub(path, 1, 1) == "/" and unicode.sub(result, 1, 1) ~= "/" then
        return "/" .. result
    else
        return result
    end
end

----------------------------------------------------

do
    local filelist, err = getInternetFile(repo .. "/filelist.txt")
    if not filelist then error(err) end
    filelist = split(filelist, "\n")

    for i = 1, #filelist do
        interrupt()
        local fullPath = filelist[i]
        local filedata, err = getInternetFile(repo .. fullPath)
        if filedata then
            fs.makeDirectory(fs_path(fullPath))
            local file, err = fs.open(fullPath, "wb")
            if file then
                status("saving: " .. fullPath)
                fs.write(file, filedata)
                fs.close(file)
            else
                status("err to save: " .. fullPath .. ", " .. (err or "unkown"))
            end
        else
            status("err to get: " .. fullPath .. ", " .. (err or "unkown"))
        end
    end
end

fs.makeDirectory("/etc")
local file = fs.open("/etc/system.cfg", "wb")
fs.write(file, "{updateRepo = \"" .. repo .. "\"}")
fs.close(file)

computer.shutdown("fast")
]])
computer.rawShutdown("fast")