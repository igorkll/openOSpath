local event = require("event")
local component = require("component")
local computer = require("computer")
local term = require("term")
local unicode = require("unicode")
local shell = require("shell")

------------------------------------asdasdad

local args, options = shell.parse(...)

if not term.isAvailable() then return end
if not component.list("internet")() then print("internet card is not found") return end  --не component.isAvailable для совместимости со старыми openOS

local gpu = term.gpu()
local depth = math.floor(gpu.getDepth())
local rx, ry = gpu.maxResolution()
gpu.setResolution(rx, ry)

------------------------------------

local function bfResevers()
    gpu.setBackground(gpu.setForeground(gpu.getBackground()))
end

local function writeStatus(posX, posY, state, bfc)
    gpu.setBackground(0)
    gpu.setForeground((state and 0x00FF00) or 0xFF0000)
    if bfc then bfResevers() end
    if not options.a then
        gpu.set(posX, posY, (state and "√") or "╳")
    else
        gpu.set(posX, posY, (state and "t") or "f")
    end
    gpu.setBackground(0)
    gpu.setForeground(0xFFFFFF)
end

local function setCenterText(posX, posY, text)
    local x = posX or (math.floor(rx / 2) - math.floor(unicode.len(text) / 2))
    local y = posY or math.floor(ry / 2)
    gpu.set(x, y, text)
    return y, x, x + (unicode.len(text) - 1)
end

------------------------------------------------------

local osUpdate = _OSVERSION ~= "OpenOS 1.7.5"
local installMyBios = not not component.list("robot")() or component.list("tablet")() --не component.isAvailable для совместимости со старыми openOS
local installMod = true
local changeLua = computer.getArchitecture and computer.getArchitecture() ~= "Lua 5.3"

------------------------------------------------------

local strs = {"  - обновить openOS до 1.7.5 (для серверов с не актуальным OC)",
"  - устоновить topBiosV5 и сменить lua на 5.3",
"  - устоновить Lua 5.3",
"  - устоновить мод для openOS"}

if rx < #strs[1] then
    strs[1] = "  - обновить openOS (для не актуального OC)"
end

local addToPosY = math.floor(ry / 2) - math.floor(5 / 2)
local maxTextSize = 0
for i = 1, #strs do
    local str = strs[i]
    if unicode.len(str) > maxTextSize then maxTextSize = unicode.len(str) end
end
local addToPosX = math.floor(rx / 2) - math.floor(maxTextSize / 2)

------------------------------------------------------

local function installer()
    term.clear()
    gpu.fill(1, 1, rx, 1, "-")
    setCenterText(nil, 1, "ход устоновки")
    term.setCursor(1, 2)
    print("компьютер может не однократно перезагрузиться, это нормально!")

    ------------------------------------------------------

    os.execute("mkdir /usr/lib")
    os.execute("wget https://raw.githubusercontent.com/igorkll/fastOS/main/usr/lib/superUtiles.lua /usr/lib/superUtiles.lua -f")
    if osUpdate then
        os.execute("wget https://raw.githubusercontent.com/igorkll/fastOS/main/getinstaller.lua /tmp/getinstaller.lua -f")
        os.execute("/tmp/getinstaller https://raw.githubusercontent.com/igorkll/openOS/main /")
    end

    local computer = require("computer")
    local su = require("superUtiles")
    local fs = require("filesystem")
    fs.setAutorunEnabled(true)

    local file = ""
    file = file .. "local osUpdate = " .. tostring(osUpdate) .. "\n"
    file = file .. "local installMyBios = " .. tostring(installMyBios) .. "\n"
    file = file .. "local installMod = " .. tostring(installMod) .. "\n"
    file = file .. "local changeLua = " .. tostring(changeLua) .. "\n"
    file = file .. [[
        if installMod then
            os.execute("wget https://raw.githubusercontent.com/igorkll/fastOS/main/getinstaller.lua /tmp/getinstaller.lua -f")
            os.execute("/tmp/getinstaller https://raw.githubusercontent.com/igorkll/openOSpath/main /")
        end

        local fs = require("filesystem")
        local computer = require("computer")

        fs.remove("/autorun.lua")
        fs.setAutorunEnabled(false)

        if installMyBios then
            os.execute("wget https://raw.githubusercontent.com/igorkll/topBiosV5/main/main /dev/eeprom -f")
        end

        if computer.setBootAddress then pcall(computer.setBootAddress, fs.get("/").address) end --от тупых биосов
        if changeLua or installMyBios then
            if computer.setArchitecture then pcall(computer.setArchitecture, "Lua 5.3") end -- от моих биосов
        end
        computer.shutdown(true)
    ]]
    su.saveFile("/autorun.lua", file)

    computer.shutdown(true)
end

local selected = 1

while true do
    gpu.setBackground(0)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1, 1, rx, ry, " ")

    gpu.fill(1, 1, rx, 1, "-")
    setCenterText(nil, 1, "openOS mod installer - v1.0")
    gpu.set(1, ry, "  - on,   - off, up down - select, enter - use")
    writeStatus(1, ry, true)
    writeStatus(9, ry, false)

    gpu.set(1 + addToPosX, 0 + addToPosY, strs[1])
    gpu.set(1 + addToPosX, 1 + addToPosY, strs[2])
    gpu.set(1 + addToPosX, 2 + addToPosY, strs[3])
    gpu.set(1 + addToPosX, 3 + addToPosY, strs[4])
    gpu.setForeground(0xFFFF00)
    if selected == 5 then bfResevers() end
    local _, commitX1, commitX2 = setCenterText(nil, 4 + addToPosY, "[commit]")
    if selected == 5 then bfResevers() end

    writeStatus(1 + addToPosX, 0 + addToPosY, osUpdate, selected == 1)
    writeStatus(1 + addToPosX, 1 + addToPosY, installMyBios, selected == 2)
    writeStatus(1 + addToPosX, 2 + addToPosY, changeLua, selected == 3)
    writeStatus(1 + addToPosX, 3 + addToPosY, installMod, selected == 4)

    -------------------------------

    local eventName, uuid, tx, ty = event.pull()
    if eventName == "touch" and uuid == term.screen() then
        tx = math.floor(tx) --для precise режима
        ty = math.floor(ty)
        if tx == (1 + addToPosX) then
            if ty == (0 + addToPosY) then
                osUpdate = not osUpdate
            elseif ty == (1 + addToPosY) then
                installMyBios = not installMyBios
            elseif ty == (2 + addToPosY) then
                changeLua = not changeLua
            elseif ty == (3 + addToPosY) then
                installMod = not installMod
            end
        elseif tx >= commitX1 and tx <= commitX2 and ty == (4 + addToPosY) then
            installer()
        end
    elseif eventName == "key_down" and uuid == term.keyboard() then
        if ty == 200 then
            if selected > 1 then selected = selected - 1 end
        elseif ty == 208 then
            if selected < 5 then selected = selected + 1 end
        elseif ty == 28 then
            if selected == 1 then
                osUpdate = not osUpdate
            elseif selected == 2 then
                installMyBios = not installMyBios
            elseif selected == 3 then
                changeLua = not changeLua
            elseif selected == 4 then
                installMod = not installMod
            elseif selected == 5 then
                installer()
            end
        end
    end
end