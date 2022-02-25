local serialization = require("serialization")
local fs = require("filesystem")
local su = require("superUtiles")
local LibDeflate = require("LibDeflate")
local unicode = require("unicode")

----------------------------------------------------

local count = 0
local function interrupt()
    count = count + 1
    if count % 512 == 0 then
        os.sleep(0.1)
    end
end

----------------------------------------------------

local lib = {}

function lib.simpleUnpack(mainpath, data)
    for path, data in pairs(data) do
        interrupt()
        path = fs.concat(mainpath, path)
        fs.makeDirectory(fs.path(path))
        su.saveFile(path, data)
    end
end

function lib.simplePack(mainpath)
    if unicode.sub(mainpath, unicode.len(mainpath), unicode.len(mainpath)) ~= "/" then mainpath = mainpath .. "/" end
    local files = {}
    local function getFolderData(path)
        interrupt()
        for data in fs.list(path) do
            interrupt()
            local fullPath = fs.concat(path, data)
            if fs.isDirectory(fullPath) then
                getFolderData(fullPath)
            else
                files[unicode.sub(fullPath, unicode.len(mainpath), unicode.len(fullPath))] = su.getFile(fullPath)
            end
        end
    end
    getFolderData(mainpath)
    return files
end

--------------------------

function lib.pack(mainpath)
    local files = lib.simplePack(mainpath)
    local raw_data = serialization.serialize(files)
    local compressData = LibDeflate.CompressDeflate("", raw_data)
    return compressData
end

function lib.unpack(mainpath, data)
    data = LibDeflate.DecompressDeflate("", data)
    data = serialization.unserialize(data)
    lib.simpleUnpack(mainpath, data)
end

return lib