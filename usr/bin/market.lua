local gui = require("simpleGui2").create()
local su = require("superUtiles")
local component = require("component")
local fs = require("filesystem")
local unicode = require("unicode")
local internet = component.internet

----------------------------------

local contentListUrl = "https://raw.githubusercontent.com/igorkll/appMarket2/main/content.txt"
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

local function tableConcat(...)
    local tbls = {...}
    local newTbl = {}
    for i = 1, #tbls do
        local tbl = tbls[i]
        for i2 = 1, #tbl do
            table.insert(newTbl, tbl[i2])
        end
    end
    return newTbl
end

local function parse(url)
    local tbl = {}
    local list = assert(getInternetFile(url))
    list = su.splitText(list, "\n")
    for i = 1, #list do
        local dat = list[i]
        local tbl2 = su.splitText(dat, ";")
        for i = 1, #tbl2 do
            if not tbl[i] then tbl[i] = {} end
            table.insert(tbl[i], tbl2[i])
        end
    end
    return tbl
end
local content = parse(contentListUrl)

----------------------------------

local rx, ry = gui.gpu.getResolution()

local function install(path, url, name)
    path = fs.concat(path, name)
    local installSplash = "вы уверенны что желаете устоновить " .. name .. "?(программа будет устоновленна по пути " .. path .. ")"
    if unicode.len(installSplash) > rx then
        gui.splash(installSplash)
        installSplash = "installer"
    end
    if gui.yesno(installSplash) then
        local file = assert(getInternetFile(url))
        su.saveFile(path, file)
    end
end

local function category(index)
    local list = parse(content[1][index])
    local num = 1
    while true do
        num = gui.menu(content[3][index], tableConcat(list[2], {"back"}), num)
        if num > #list[2] then break end
        install(content[2][index], list[1][num], list[2][num])
    end
end

----------------------------------

local num = 1
while true do
    num = gui.menu("select category", tableConcat(content[3], {"back"}), num)
    if num > #content[3] then gui.exit() end
    category(num)
end