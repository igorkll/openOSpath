local fs = require("filesystem")
local computer = require("computer")
local unicode = require("unicode")
local su = require("superUtiles")

--------------------------------------------

--afp - archive files pack
local nullchar = string.char(0)

--------------------------------------------

local lib = {}

function lib.pack(dir, outputpath)
    dir = fs.canonical(dir)
    local files = {}
    local function process()
        local outputfile = assert(io.open(outputpath, "wb"))
        table.insert(files, outputfile)
        outputfile:write("AFP_____")

        local function addfile(path)
            local full_path = fs.concat(dir, path)
            outputfile:write(path .. nullchar)
            outputfile:write(tostring(math.floor(fs.size(full_path))) .. nullchar)

            local file, err = fs.open(full_path, "rb")
            if not file then error("error: " .. err .. " to open file " .. full_path, 0) end
            table.insert(files, file)
            while true do
                local data = file:read(math.huge)
                if not data then break end
                outputfile:write(data)
            end
            su.tableRemove(files, file)
            file:close()
        end
        local function recurse(ldir)
            local archpath = unicode.sub(ldir, unicode.len(dir) + 1, unicode.len(ldir))
            if archpath:sub(1, 1) ~= "/" then archpath = "/" .. archpath end

            for path in fs.list(ldir) do
                local full_path = fs.concat(ldir, path)
                if fs.isDirectory(full_path) then
                    recurse(full_path)
                else
                    --print("archpath", archpath, "path", path)
                    addfile(fs.concat(archpath, path))
                end
            end
        end
        recurse(dir)
        su.tableRemove(files, outputfile)
        outputfile:close()
    end

    local ret = {pcall(process)}
    for i, v in ipairs(files) do
        v:close()
    end
    return table.unpack(ret)
end

function lib.unpack(inputpath, dir)
    dir = fs.canonical(dir)
    local files = {}
    local function process()
        local inputfile = assert(io.open(inputpath, "rb"))
        table.insert(files, inputfile)

        local signature = inputfile:read(8)
        if signature == "AFP_____" then --archive files pack
            local function read()
                local data = ""
                while true do
                    local ldata = inputfile:read(1)
                    if not ldata or ldata == nullchar then break end
                    data = data .. ldata
                end
                return data
            end
            while true do
                --print("while")
                local path = read()
                if path == "" then break end
                --print("PATH", path)
                local filesize = tonumber(read())
                --print("SIZE", filesize)

                local path = fs.concat(dir, path)
                fs.makeDirectory(fs.path(path))
                local file = assert(fs.open(path, "wb"))
                table.insert(files, file)
                while true do
                    local data = inputfile:read(filesize)
                    if not data then break end
                    filesize = filesize - #data
                    file:write(data)
                    if filesize <= 0 then break end
                end
                su.tableRemove(files, file)
                file:close()
            end
        else
            error("this arhive format is not supported", 0)
        end

        su.tableRemove(files, inputfile)
        inputfile:close()
    end

    local ret = {pcall(process)}
    for i, v in ipairs(files) do
        v:close()
    end
    return table.unpack(ret)
end

return lib