local event = require("event")
local su = require("superUtiles")
local component = require("component")
local fs = require("filesystem")
local wget = loadfile("/bin/wget.lua")
local term = require("term")
local process = require("process")
local unicode = require("unicode")
local originalInterrupt = process.info().data.signal
local gui = require("gui_new").create()
if not component.isAvailable("internet") then
    print("internet card is not found")
    print("press enter to continue...")
    event.pull("key_down", gui.keyboard, nil, 28)
    return
end
local internet = component.internet

--------------------------------------------------

local appsListUrl = "https://raw.githubusercontent.com/igorkll/appMarket2/main/lib/list.txt"
local gpu = gui.gpu
local rx, ry = gpu.getResolution()

--------------------------------------------------

local function executeInZone(wait, func, ...)
    local oldScene = gui.getScene()
    local oldInterrupt = process.info().data.signal

    gui.select(0)
    local oldb = gpu.setBackground(0)
    local oldf = gpu.setForeground(0xFFFFFF)
    gpu.setResolution(gpu.maxResolution())
    local rx, ry = gpu.getResolution()
    gpu.fill(1, 1, rx, ry, " ")

    process.info().data.signal = originalInterrupt
    local out = {pcall(func, ...)}
    if not out[1] then print(out[2] or "unkown") end
    process.info().data.signal = oldInterrupt

    if wait then
        print("press enter to continue...")
        while true do
            local eventName, uuid, _, code = event.pull()
            if eventName == "key_down" and uuid == term.keyboard() and code == 28 then
                break
            end
        end
    end

    gpu.setBackground(oldb)
    gpu.setForeground(oldf)

    gui.select(oldScene or 0)
    return table.unpack(out)
end

local function runCommand(command, wait)
    executeInZone(wait, os.execute, command)
end

local function runFile(path, wait, ...)
    executeInZone(wait, shell.execute, path, _ENV, ...)
end

--------------------------------------------------

local drawIndex = su.generateRandomID()

local main = gui.createScene()
main.createDrawZone(1, 1, rx, ry, function() end, drawIndex)
local logZone = main.createLogZone(1, 1, rx, ry, nil, nil, nil, nil, false)
logZone.autodraw = false

gui.select(main)

--------------------------------------------------

local function split(str, sep)
    local parts, count = {}, 1
    for i = 1, unicode.len(str) do
        local char = unicode.sub(str, i, i)
        if not parts[count] then parts[count] = "" end
        if char == sep then
            count = count + 1
        else
            parts[count] = parts[count] .. char
        end
    end
    return parts
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

local indexed = {}

local function reindex()
    logZone.clear()
    local appsList, err = getInternetFile(appsListUrl)
    if not appsList then gui.splash("произошла ошибка, возможно нет соенденения с интернетом") gui.exit() end
    local strs = split(appsList, "\n")
    for i = 1, #strs do
        local url, name = table.unpack(split(strs[i], ";"))
        indexed[name] = url
        logZone.add(name)
    end
    logZone.draw()
end
reindex()

--------------------------------------------------

local lastTouchX, lastTouchY

while true do
    local eventData = {event.pull()}
    if eventData[1] == "touch" and eventData[2] == term.screen() then
        lastTouchX = eventData[3]
        lastTouchY = eventData[4]
    end
    gui.uploadEvent(table.unpack(eventData))
    if eventData[1] == "drawZone" and eventData[2] == "touch" and eventData[3] == drawIndex then
        local posX = eventData[4]
        local posY = eventData[5]
        local text = logZone.strs[posY]
        local url = indexed[text]

        if eventData[6] == 0 then
            if url and gui.yesno("вы уверенны что хотите устоновить "..text.."?") then
                fs.makeDirectory("/usr/lib")
                executeInZone(true, wget, url, fs.concat("/usr/lib", text), "-f")
                if shell_reindex then shell_reindex() end
            end
        end
    end
end