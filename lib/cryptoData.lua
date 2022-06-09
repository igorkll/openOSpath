local lib = {}

--------------------------------------------зашишенное хранилишя данных

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

--------------------------------------------ограничения прав доступа

local globalPermitsPassword
local permits = {}

function lib.setGlobalPermitsPassword(password)
    if globalPermitsPassword then
        return false
    else
        globalPermitsPassword = password
        return true
    end
end

function lib.isGlobalPermitsPassword()
    return not not globalPermitsPassword
end


return lib