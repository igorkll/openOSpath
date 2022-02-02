local fs = require("filesystem")
local term = require("term")
local component = require("component")
local su = require("superUtiles")
local unicode = require("unicode")
local term = require("term")
local tty = require("tty")

-----------------------------------------------------

local screenpath = "/etc/screen.cfg"
local gpupath = "/etc/gpu.cfg"

-----------------------------------------------------

local systemscreen = (fs.exists(screenpath) and su.getFile(screenpath)) or "*"
local systemgpu = (fs.exists(gpupath) and su.getFile(gpupath)) or "*"

systemscreen = component.proxy(systemscreen)
systemgpu = component.proxy(systemgpu)

if systemscreen then
    component.setPrimary("screen", systemscreen.address)
else
    local screen = component.list("screen")()
    if screen then
        su.saveFile(screenpath, screen)
    else
        fs.remove(screenpath)
    end
end

if systemgpu then
    component.setPrimary("gpu", systemgpu.address)
    systemgpu.bind(systemscreen.address)
else
    local gpu = component.list("gpu")()
    if gpu then
        su.saveFile(gpupath, gpu)
    else
        fs.remove(gpupath)
    end
end

-----------------------------------------------------

local oldProxy = component.proxy
local function newProxy(address)
    local proxy, err = oldProxy(address)
    if not proxy then return nil, err end
    if proxy.type == "screen" then
        local screengpu
        for address in component.list("gpu") do
            local gpu = oldProxy(address)
            if gpu.getScreen() == proxy.address then
                screengpu = gpu
            end
        end
        if screengpu then
            proxy.gpu = screengpu
        end
    end
    return proxy
end
component.proxy = newProxy