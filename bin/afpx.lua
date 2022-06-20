local afpx = require("afpx")
local shell = require("shell")
local fs = require("filesystem")

local args, options = shell.parse(...)

--------------------------------------------

if args[1] == "pack" then
    local dir = shell.resolve(args[2])
    local file = shell.resolve(args[3])

    if not file or not fs.exists(dir) then io.stderr:write("no this directory\n") return end
    if not dir or not fs.isDirectory(dir) then io.stderr:write("directory is file\n") return end

    if fs.exists(file) and not options.f then io.stderr:write("file already exists\n") return end
    if fs.isDirectory(file) then io.stderr:write("file is directory\n") return end

    assert(afpx.pack(dir, file))
elseif args[1] == "unpack" then
    local file = shell.resolve(args[2])
    local dir = shell.resolve(args[3])

    if not fs.exists(file) then io.stderr:write("file not found\n") return end
    if fs.isDirectory(file) then io.stderr:write("file is directory\n") return end
    
    if fs.exists(dir) and not fs.isDirectory(dir) then io.stderr:write("directory is file\n") return end

    assert(afpx.unpack(file, dir))
else
    print("afpx pack direcory outputfile")
    print("afpx unpack inputfile direcory")
end