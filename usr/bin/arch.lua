local arch = require("archlib2")
local su = require("superUtiles")
local shell = require("shell")

local args = shell.parse(...)

------------------------------------

if args[1] == "pack" then
    local dir = shell.resolve(args[2])
    local out = shell.resolve(args[3])

    local data = arch.pack(dir)
    su.saveFile(out, data)
elseif args[1] == "unpack" then
    local file = shell.resolve(args[2])
    local dir = shell.resolve(args[3])

    local data = su.getFile(file)
    arch.unpack(dir, data)
else
    print("arch pack directory outputfile")
    print("arch unpack inputfile outputdirectory")
end