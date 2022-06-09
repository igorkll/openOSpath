return {create = function()
    local env = {}
    env.assert = assert
    env.collectgarbage = collectgarbage
    env.error = error
    env.getmetatable = getmetatable
    env.ipairs = ipairs
    env.load = load
    env.next = next
    env.pairs = pairs
    env.pcall = pcall
    env.rawequal = rawequal
    env.rawget = rawget
    env.rawlen = rawlen
    env.rawset = rawset
    env.select = select
    env.setmetatable = setmetatable
    env.tonumber = tonumber
    env.tostring = tostring
    env.type = type
    env.xpcall = xpcall
    env.coroutine = coroutine
    env.string = string
    env.utf8 = utf8
    env.table = table
    env.math = math
    env.debug = debug
    env.checkArg = checkArg
    env.os = {}
    env.os.data = os.data
    env.bit32 = require("bit32")
    env.bit = env.bit32
    env.unicode = require("unicode")

    return env
end}