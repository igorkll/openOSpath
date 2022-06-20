local su = require("superUtiles")
local fs = require("filesystem")
local component = require("component")
local computer = require("computer")
local sha256 = require("sha256lib").sha256
local serialization = require("serialization")
local shell = require("shell")

local args, options = shell.parse(...)

--------------------------------------------------

print("вас приветствует программа recoverytool")
print("при помоши ее вы сможете востановить функциональность стороньнего устройства")
print("если это планшет достаточьно подключить его к зарядке")
print("если это робот, его необходимо разобрать и подключить жеский диск к компьютеру")
print("если это компьютер/сервер необходимо подключить его жеский диск к компьютеру")
print("чтобы диск определился в программе он должен считаться загрузочьным")
print("если ваш диск по той или оний причине не определяеться в программе используйте ключ запуска -a")
print("если и это не помогло используйте ключ -A")

local devices = {}
for address in component.list("filesystem") do
    local mountpath = "/free/tempMounts/device"
    fs.umount(mountpath)
    fs.mount(component.proxy(address), mountpath)
    if ((address ~= fs.get("/").address and address ~= computer.tmpAddress() and not su.isLoot(address)) or options.A) and
    ((fs.exists(fs.concat(mountpath, "init.lua")) or fs.exists(fs.concat(mountpath, "OS.lua"))) or options.a or options.A) then
        table.insert(devices, address)
    end
    fs.umount(mountpath)
end

local function printDevice(address)
    local mountpath = "/free/tempMounts/device"
    fs.umount(mountpath)
    fs.mount(component.proxy(address), mountpath)

    local function get(path)
        path = fs.concat(mountpath, path)
        return fs.exists(path) and assert(su.getFile(path)) or "unkown"
    end

    print(su.getFullInfoParts(address))
    --------------------
    if options.w and false then --disabled
        print("последьния включения:")
        print("тип устройства: " .. get("free/current/deviceType"))
        print("адрес устройства: " .. get("free/current/deviceAddress"))
        print("адрес файловой системы: " .. get("free/current/fsAddress"))
        print("адрес eeprom: " .. get("free/current/startEepromAddress"))
        print("systemID: " .. get("free/current/systemUuid"))
        print("--------------------")
        print("первое включения:")
        print("тип устройства: " .. get("free/unical/deviceType"))
        print("адрес устройства: " .. get("free/unical/deviceAddress"))
        print("адрес файловой системы: " .. get("free/unical/fsAddress"))
        print("адрес eeprom: " .. get("free/unical/startEepromAddress"))
        print("systemID: " .. get("free/unical/systemUuid"))
    end

    fs.umount(mountpath)
end

print("-----------------------------------------")
for i, v in ipairs(devices) do
    io.write(tostring(i) .. ". ")
    printDevice(v)
    print("-----------------------------------------")
end

--------------------------------------------------

::reselect::
io.write("выберите устройства: ")
local read = io.read()
if not read then return end
local device = devices[tonumber(read)]
if not device then
    print("ошибка ввода")
    goto reselect
end

--------------------------------------------------

local mountpath = "/free/tempMounts/unitoolDevice"
local deviceproxy = component.proxy(device)
fs.umount(mountpath)
fs.mount(deviceproxy, mountpath)
if fs.exists(fs.concat(mountpath, "etc/lock.cfg")) then
    local lockCfg = assert(serialization.unserialize(assert(su.getFile(fs.concat(mountpath, "etc/lock.cfg")))))
    local passwordHesh = lockCfg.passwordSha256
    if passwordHesh then
        ::reinput::
        io.write("введите пароль от устройства: ")
        local read = io.read()
        if not read then return end
        if sha256(read) ~= passwordHesh then
            print("неправильный пароль")
            goto reinput
        end
    end
end

print("вы выбрали устройства:")
printDevice(device)

--------------------------------------------------

print("--------------------")
print("рекомендации:")
print("сначала сделайте сброс пароля")
print("если это не поможет востановить функциональность устройства")
print("произведите сброс настроек")
print("если и это не поможет, попробуйте прошить без потери данных")
print("если устройство и после этого не заработает, воспользуйтесь перепрошивкой с потеряй данных")
print("если и после этого устройства не начнет работать скорее всего проблемма в bios или железе")
print("--------------------")
while true do
    print("1.прошить openOSmod с потеряй данных(рекомендуеться)")
    print("2.прошить openOSmod без потери данных(ненадежно)")
    print("3.сбросить пароль")
    print("4.сбросить настройки")
    print("выберите действия:")

    local read = io.read()
    if not read then return end
    local read = tonumber(read)
    if read == 1 or read == 2 then
        local repos = {{"https://raw.githubusercontent.com/igorkll/openOSpath/main", "main(рекомендуеться)"}, {"https://raw.githubusercontent.com/igorkll/openOSpath/dev", "dev(тестовый канал, может быть нестабилен)"}, {"custom", "custom(выбрать свою прошивку в формате plex)"}}
        local repo
        while true do
            print("выберите прошивку:")
            for i, v in ipairs(repos) do
                print(tostring(i) .. ".", v[2])
            end
            local read = io.read()
            if not read then break end
            local num = tonumber(read)
            if not num and num < 1 and num > #repos then
                print("ошибка ввода.")
            else
                repo = repos[num][1]
                break
            end
        end

        if repo == "custom" then
            local path
            while true do
                print("введите путь до прошивки")
                local lpath = io.read()
                if fs.isDirectory(lpath) then
                    print("это директория")
                elseif not fs.exists(lpath) then
                    print("нет этого файла")
                else
                    path = lpath
                    break
                end
            end
            if read == 1 then
                print("форматирования...")
                deviceproxy.remove("/")
                print("форматирования зевершено.")
            end
            print("прошивка...")
            local afpx = require("afpx")
            assert(afpx.unpack(path, mountpath))
            print("прошивка зевершена.")
        else
            if su.isInternet() then
                if read == 1 then
                    print("форматирования...")
                    deviceproxy.remove("/")
                    print("форматирования зевершено.")
                end
                print("прошивка...")
                su.saveTable(fs.concat(mountpath, "etc/system.cfg"), {updateRepo = repo})
                os.execute("getinstaller https://raw.githubusercontent.com/igorkll/openOS/main -q " .. mountpath)
                os.execute("getinstaller " .. repo .. " -q " .. mountpath)
                print("прошивка зевершена.")
            else
                print("упс, для этой прошивки требуеться интернет")
            end
        end
    elseif read == 3 then
        deviceproxy.remove("/etc/lock.cfg")
        print("пароль сброшен.")
    elseif read == 4 then
        deviceproxy.remove("/etc/system.cfg")
        print("настройки сброшены.")
    else
        print("ошибка ввода.")
    end
end