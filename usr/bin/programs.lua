local fs = require("filesystem")
local shell = require("shell")

local args, options = shell.parse(...)

if #args == 0 then
    print("Usage:")
    print("programs list")
    print("programs command name command(uninstall/run/lalala/blablabla/any)")
    return
end

--------------------------------------------

if args[1] == "list" then
    for file in fs.list("/free/programs/menagers") do
        print(file)
    end
elseif args[1] == "command" then
    local programmPath = fs.concat("/free/programs/menagers", args[2])
    if fs.exists(programmPath) then
        require("shell").execute(programmPath, nil, args[3])
    else
        print("no this programm")
    end
end