local su = require("superUtiles")
local component = require("component")
local event = require("event")

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



function lib.addFilterMethod(address, method, func)
    local proxy, err = component.proxy(address)
    if not proxy then return nil, err end
    

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
        table.insert(list, v)
    end

    return list
end

function lib.isReadOnly(path)
    return su.inTable(lib.getGlobalReadOnlyFiles(), path)
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

return lib