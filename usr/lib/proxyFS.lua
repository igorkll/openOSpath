local fs = require("filesystem")

------------------------------------------

local lib = {}

lib.getPathValue = function(path)
    local path = fs.canonical(path)
    if path:sub(#path, #path) ~= "/" then
        path = path.."/"
    end
    local value = -1
    for i = 1, #path do
        if path:sub(i,i) == "/" then
            value = value + 1
        end
    end
    return value+1
end

lib.rePath = function(path, fspath)
    local new = fs.concat(path, fspath)
    if lib.getPathValue(new) < lib.getPathValue(path) then
        new = path
    end
    return new
end

lib.createFS = function(path, label)
    local path = path
    local label = label or "sandbox"
    local obj = {}

    obj.open = function(...)
        local data = table.pack(...)
        data[1] = lib.rePath(path, data[1])
        return fs.open(table.unpack(data))
    end
    obj.exists = function(...)
        local data = table.pack(...)
        data[1] = lib.rePath(path, data[1])
        return fs.exists(table.unpack(data))
    end
    obj.isDirectory = function(...)
        local data = table.pack(...)
        data[1] = lib.rePath(path, data[1])
        return fs.isDirectory(table.unpack(data))
    end
    obj.lastModified = function(...)
        local data = table.pack(...)
        data[1] = lib.rePath(path, data[1])
        return fs.lastModified(table.unpack(data))
    end
    obj.list = function(...)
        local data = table.pack(...)
        data[1] = lib.rePath(path, data[1])
        return fs.list(table.unpack(data))
    end
    obj.makeDirectory = function(...)
        local data = table.pack(...)
        data[1] = lib.rePath(path, data[1])
        return fs.makeDirectory(table.unpack(data))
    end
    obj.remove = function(...)
        local data = table.pack(...)
        data[1] = lib.rePath(path, data[1])
        return fs.remove(table.unpack(data))
    end
    obj.rename = function(...)
        local data = table.pack(...)
        data[1] = lib.rePath(path, data[1])
        data[2] = lib.rePath(path, data[2])
        return fs.rename(table.unpack(data))
    end
    obj.size = function(...)
        local data = table.pack(...)
        data[1] = lib.rePath(path, data[1])
        return fs.size(table.unpack(data))
    end

    obj.spaseTotal = function() return math.huge end
    obj.spaseUsed = function() return 0 end

    obj.getLabel = function() return label end
    obj.setLabel = function(new) local old = label; label = new; return old end

    obj.isReadOnly = function() return false end

    obj.read = function(...) return fs.read(...) end
    obj.close = function(...) return fs.close(...) end
    obj.seek = function(...) return fs.seek(...) end
    obj.write = function(...) return fs.write(...) end

    return obj
end

return lib