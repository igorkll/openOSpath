local bizicall = require("bizicall")
local event = require("event")
local component = require("component")

-----------------------------------------------

local lib = {}

local function tofunction(value)
    return type(value) == "function" or (type(value) == "table" and getmetatable(value) and getmetatable(value).__call)
end

function lib.hostProxy(name, proxy)
    local obj = {}
    obj.name = name
    obj.proxy = proxy
    obj.hosts = {}
    for key, value in pairs(proxy) do
        local func = tofunction(value)
        if func then
            obj.hosts[#obj.hosts + 1] = bizicall.create("call:"..obj.name..":"..key, tofunction(func) or error("func get err"))
        end
    end
    local function getFunctions()
        local strs = {}
        for key, value in pairs(proxy) do
            if tofunction(value) then
                strs[#strs + 1] = key
            end
        end
        local str = table.concat(strs, ":")
        local address
        if type(proxy.address) == "string" then
            address = proxy.address
        elseif type(proxy.address) == "function" then
            address = proxy.address()
        end
        local ctype
        if type(proxy.type) == "string" then
            ctype = proxy.type
        end
        return str, address, ctype
    end
    obj.hosts[#obj.hosts + 1] = bizicall.create("getMetods:"..obj.name, getFunctions)
    obj.kill = function()
        for i = 1, #obj.hosts do
            obj.hosts[i].kill()
        end
    end

    return obj
end

function lib.getProxy(name)
    local proxy = {}
    
    local str, address, type = bizicall.call("getMetods:"..name)
    local functionsnames = {}
    for substr in str:gmatch("[^:]+") do
        functionsnames[#functionsnames + 1] = substr
    end
    proxy.address = address
    proxy.type = type
    proxy.slot = -1

    for i = 1, #functionsnames do
        proxy[functionsnames[i]] = function(...)
            return bizicall.call("call:"..name..":"..functionsnames[i], ...)
        end
    end

    return proxy
end

function lib.register(name)
    local vcomponent = require("vcomponent")
    local proxy = lib.getProxy(name)

    return vcomponent.register(proxy.address, proxy.type, proxy, "")
end

function lib.share(name, address)
    local proxy, err = component.proxy(address)
    if not proxy then
        return nil, err
    end
    return lib.hostProxy(name, proxy)
end

return lib