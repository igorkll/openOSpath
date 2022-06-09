local su = require("superUtiles")
local component = require("component")
local event = require("event")
local fs = require("filesystem")

--------------------------------------------

local lib = {}

--зашишенное хранилишя данных

local cryptoDatasPassword = {}
local cryptoDatas = {}

function lib.setCryptoData(name, password, data)
    if cryptoDatas[name] then
        if password == cryptoDatasPassword[name] then
            cryptoDatas[name] = data
            return true
        else
            return false, "uncorrect password"
        end
    else
        cryptoDatas[name] = data
        cryptoDatasPassword[name] = password
        return true
    end
end

function lib.isCryptoData(name)
    return not not cryptoDatas[name]
end

function lib.removeCryptoData(name, password)
    if cryptoDatas[name] then
        if password == cryptoDatasPassword[name] then
            cryptoDatas[name] = nil
            cryptoDatasPassword[name] = nil
            return true
        else
            return false, "uncorrect password"
        end
    else
        return false, "no this data part"
    end
end

function lib.getCryptoData(name, password)
    if cryptoDatas[name] then
        if password == cryptoDatasPassword[name] then
            return cryptoDatas[name]
        else
            return false, "uncorrect password"
        end
    else
        return false, "no this data part"
    end
end

--подмена доступа к компонентам

local fakeMethods = {}
local origInvoke = component.invoke

function component.invoke(address, method, ...)
    if fakeMethods[address] then
        if fakeMethods[address][method] then
            return fakeMethods[address][method](address, function(...)
                return origInvoke(address, method, ...)
            end, method, ...)
        end
    end
    return origInvoke(address, method, ...)
end

function lib.addFilterMethod(address, methodName, toFunc)
    local proxy, err = component.proxy(address)
    if not proxy then return nil, err end
    
    if not fakeMethods[address] then fakeMethods[address] = {} end
    fakeMethods[address][methodName] = toFunc

    return function()
        if fakeMethods[address][methodName] then
            fakeMethods[address][methodName] = nil
            return true
        end
        return false
    end
end

--ограничения прав доступа

local globalPermitsPassword
local readonlyLists = {}

function lib.setGlobalPermitsPassword(password)
    if globalPermitsPassword then
        return false, "global permits password setted"
    else
        globalPermitsPassword = password
        return true
    end
end

function lib.resetGlobalPermitsPassword(password)
    if not globalPermitsPassword then
        return false, "global permits password is not setted"
    else
        if password == globalPermitsPassword then
            globalPermitsPassword = nil
            return true
        else
            return false, "uncorrect global password"
        end
    end
end

function lib.isGlobalPermitsPassword()
    return not not globalPermitsPassword
end

function lib.getGlobalReadOnlyFiles()
    local list = {}

    for k, v in ipairs(readonlyLists) do
        for k, v in ipairs(v) do
            table.insert(list, v)
        end
    end

    return list
end

function lib.isReadOnly(path)
    return su.inTable(lib.getGlobalReadOnlyFiles(), fs.canonical(path))
end

function lib.addReadOnlyList(globalPassword, tbl)
    if not globalPermitsPassword or globalPermitsPassword == globalPassword then
        if not su.inTable(readonlyLists, tbl) then
            table.insert(readonlyLists, tbl)
            return true
        else
            return false, "this list has already been added"
        end
    end
    return false, "uncorrect global password"
end

function lib.resetReadOnlyList(globalPassword, tbl)
    if not globalPermitsPassword or globalPermitsPassword == globalPassword then
        if su.inTable(readonlyLists, tbl) then
            su.tableRemove(readonlyLists, tbl)
            return true
        else
            return false, "list is not found"
        end
    end
    return false, "uncorrect global password"
end

local function customFsMethod(_, method, methodName, ...)
    local tbl = {...}
    if methodName == "open" then
        if tbl[2]:sub(1, 1) == "w" and tbl[2]:sub(1, 1) == "a" and lib.isReadOnly(tbl[1]) then return nil, "file is readonly" end
    elseif methodName == "copy" then
        if lib.isReadOnly(tbl[2]) then return nil, "file is readonly" end
    elseif methodName == "rename" then
        if lib.isReadOnly(tbl[1]) or lib.isReadOnly(tbl[2]) then return nil, "file is readonly" end
    elseif methodName == "remove" then
        if lib.isReadOnly(tbl[1]) then return nil, "file is readonly" end
    end
    return method(...)
end

local address = fs.get("/").address
lib.addFilterMethod(address, "open", customFsMethod)
lib.addFilterMethod(address, "copy", customFsMethod)
lib.addFilterMethod(address, "rename", customFsMethod)
lib.addFilterMethod(address, "remove", customFsMethod)

return lib