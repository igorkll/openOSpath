local component = require("component")
local shell = require("shell")
local fs = require("filesystem")
local su = require("superUtiles")
local unicode = require("unicode")
local internet = component.internet

----------------------------------------------------

local args, options = shell.parse(...)
local url = args[1]
local installpath = args[2]

----------------------------------------------------

local function getInternetFile(url)
    local handle, data, result, reason = internet.request(url), ""
    if handle then
        while true do
            result, reason = handle.read(math.huge)	
            if result then
                data = data .. result
            else
                handle.close()
                
                if reason then
                    return nil, reason
                else
                    return data
                end
            end
        end
    else
        return nil, "unvalid address"
    end
end

local function split(str, sep)
    local parts, count, i = {}, 1, 1
    while 1 do
        if i > #str then break end
        local char = str:sub(i, #sep + (i - 1))
        if not parts[count] then parts[count] = "" end
        if char == sep then
            count = count + 1
            i = i + #sep
        else
            parts[count] = parts[count] .. str:sub(i, i)
            i = i + 1
        end
    end
    if str:sub(#str - (#sep - 1), #str) == sep then table.insert(parts, "") end
    return parts
end
----------------------------------------------------

local filelist, err = getInternetFile(url.."/filelist.txt")
if not filelist then error(err) end
filelist = split(filelist, "\n")

local ignoreList = {}

local function isIgnore(path)
    return su.inTable(ignoreList, fs.canonical(path)) and options.i
end

if fs.exists("/ignoreUpdate.txt") then
    ignoreList = su.split(assert(su.getFile("/ignoreUpdate.txt")), "\n")
else
    ignoreList = {}
end

----------------------------------------------------

_G.installFiles = #filelist
for i = 1, #filelist do
    _G.installedFiles = i
    local file = filelist[i]
    local fileurl = url..file
    local filedata, err = getInternetFile(fileurl)
    local fullPath = fs.concat(installpath, file)
    if not options.q then print(fullPath) end
    if filedata then
        if not isIgnore(fullPath) then
            su.saveFile(fullPath, filedata)
        end
    else
        if not options.q then print("error: "..(err or "unlown")) end
    end
    interrupt()
end