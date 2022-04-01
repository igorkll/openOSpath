local component = require("component")
local event = require("event")
local term = require("term")
local computer = require("computer")
local fs = require("filesystem")
local su = require("superUtiles")

if not component.isAvailable("gpu") or not component.isAvailable("screen") then return end

---------------------------------------------

local connectedScreen
local connectedGpu
local function setGS(screen, gpu)
    component.setPrimary("gpu", gpu)
    component.setPrimary("screen", screen)
    component.invoke(gpu, "bind", screen)

    term.bind(component.proxy(gpu))

    connectedScreen = screen
    connectedGpu = gpu
end

local function getDeviceLevel(address)
    return tonumber(computer.getDeviceInfo()[address].width) or 0
end

local function getMax(filter)
    local maxlevel = 0
    local deviceaddress = nil
    local finded = false

    while true do
        finded = false
        for address in component.list(filter) do
            local level = getDeviceLevel(address)
            if level > maxlevel then
                maxlevel = level
                deviceaddress = address
                finded = true
                break
            end
        end
        if not finded then
            return deviceaddress
        end
    end
end

---------------------------------------------

local screenpath = "/etc/screen.cfg"

local function reconnect()
    if computer.getBootScreen and computer.getBootGpu then
        local screen = computer.getBootScreen()
        local gpu = computer.getBootGpu()
        if screen and gpu then
            su.saveFile(screenpath, screen)
            setGS(screen, gpu)
            return
        end
    end

    local maxgpu = getMax("gpu")

    if fs.exists(screenpath) then
        local screen = component.proxy(assert(su.getFile(screenpath)))
        local gpu = component.proxy(maxgpu)
        if screen and gpu then
            setGS(screen.address, gpu.address)
            return
        end
    end

    local maxscreen = getMax("screen")
    setGS(maxscreen, maxgpu)
    su.saveFile(screenpath, maxscreen)
end

xpcall(reconnect, function(str) event.onError(str .. debug.traceback) end)
--term.clear()