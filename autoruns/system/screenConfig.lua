local component = require("component")
local event = require("event")
local term = require("term")
local computer = require("computer")
local fs = require("filesystem")
local su = require("superUtiles")

---------------------------------------------

local connectedScreen
local connectedGpu
local function setGS(screen, gpu)
    component.invoke(gpu, "bind", screen)
    component.setPrimary("gpu", gpu)
    term.bind(component.proxy(gpu))
    component.setPrimary("screen", screen)
    connectedScreen = screen
    connectedGpu = gpu
end

local function getDeviceLevel(address)
    return tonumber(computer.getDeviceInfo()[address].width)
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
local gpupath = "/etc/gpu.cfg"

local function reconnect()
    if fs.exists(screenpath) and fs.exists(gpupath) then
        local screen = component.proxy(assert(su.getFile(screenpath)))
        local gpu = component.proxy(assert(su.getFile(gpupath)))
        if screen and gpu then
            setGS(screen.address, gpu.address)
            return
        end
    end

    local maxgpu = getMax("gpu")
    local maxscreen = getMax("screen")
    setGS(maxscreen, maxgpu)
    su.saveFile(screenpath, maxscreen)
    su.saveFile(gpupath, maxgpu)
end

reconnect()