local component = require("component")
local fs = require("filesystem")
local su = require("superUtiles")
local computer = require("computer")
local serialization = require("serialization")

local deviceinfo = computer.getDeviceInfo()

-------------------------------------------------

local loots = {}
local targets = {}

local function isLoot(address)
    local perms = su.getPerms(component.proxy(address))
    return not perms.noLoot and (perms.loot or (deviceinfo[address] and deviceinfo[address].clock == "20/20/20"))
end

local function getData(proxy) --часть кода из mineOS efi
    return proxy.isReadOnly() and "R" or "R/W", "type: " .. (proxy.spaceTotal() >= 1048576 and "HDD" or proxy.spaceTotal() >= 65536 and "FDD" or "SYS"), "mount: " .. (su.getMountPoint(proxy.address) or "none")
end

for address in component.list("filesystem") do
    local proxy = component.proxy(address)
    local perms = su.getPerms(proxy)
    local loot = isLoot(address)
    if loot then
        table.insert(loots, address)
    elseif not perms.nonTarget and not proxy.isReadOnly() then
        table.insert(targets, address)
    end
end

if #loots == 0 then
    print("отсутствуют loot диски")
    return
end

if #targets == 0 then
    print("отсутствует диск куда может быть произведена устоновка")
    return
end

-------------------------------------------------

print("-----------------")
print("устоновочные начители")
for i, address in ipairs(loots) do
    local proxy = component.proxy(address)
    local label = proxy.getLabel() or address:sub(1, 5)
    print(tostring(i) .. ". " .. label, getData(proxy))
end
print("-----------------")

local from
while true do
    io.write("выберите устоновочный наситель: ")
    local read = io.read()
    if not read then return end
    local num = tonumber(read)
    from = loots[num]
    if from then
        print("для устоновки выбран диск", component.invoke(from, "getLabel") or from:sub(1, 5))
        break
    end
    print("ошибка ввода, ввидите номер диска или нажмите ctrl + c чтобы покинуть устоновшик")
end

print("-----------------")
print("диск куда может быть произведена устоновка")
for i, address in ipairs(targets) do
    local proxy = component.proxy(address)
    local label = proxy.getLabel() or address:sub(1, 5)
    print(tostring(i) .. ". " .. label, getData(proxy))
end
print("-----------------")

local target
while true do
    io.write("выберите диск куда будет произведена устоновка: ")
    local read = io.read()
    if not read then return end
    local num = tonumber(read)
    target = targets[num]
    if target then
        print("устоновка будет произведена на диск", component.invoke(target, "getLabel") or target:sub(1, 5))
        break
    end
    print("ошибка ввода, ввидите номер диска или нажмите ctrl + c чтобы покинуть устоновшик")
end

local fromProxy = component.proxy(from)
local targetProxy = component.proxy(target)
local driveName = fromProxy.getLabel() or from:sub(1, 5)
local targetDriveName = (fromProxy.getLabel() or "noLabel") .. ":" .. from:sub(1, 5)

if targetProxy.exists(fs.concat("/free/uninstallers", driveName)) then
    print("-----------------")
    print("программа " .. driveName .. " уже устоновленная на диске " .. targetDriveName)
    print("устоновка поверх невозможна, если вы желаете обновить программу")
    print("ее сначало нужно удалить воспользовавшись утилитой uninstall")
    return
end

print("-----------------")
io.write("вы уверены произвести устоновку " .. (component.proxy(from).getLabel() or from:sub(1, 5)) .. " на диск " .. ((component.proxy(target).getLabel() or "noLabel") .. ":" .. target:sub(1, 5)) .. " [Y/y] ")
local ok = io.read()
if ok ~= "y" and ok ~= "Y" and ok ~= "" then ok = false end
if not ok then return end
print("-----------------")

-----------------------------------------

_G.installFlag = true

local oldfiles
if not fromProxy.exists("/.uninstall") then oldfiles = su.getFsFiles(target) end

os.execute("oldinstall --from=" .. from .. " --to=" .. target .. " -y")

local newfiles
if not fromProxy.exists("/.uninstall") then newfiles = su.getFsFiles(target) end

_G.installFlag = false

-----------------------------------------

local subfiles
if oldfiles and newfiles then
    subfiles = {}
    for i = 1, #newfiles do
        if not su.inTable(oldfiles, newfiles[i]) then
            table.insert(subfiles, newfiles[i])
        end
    end
end
if #subfiles == 0 then subfiles = nil end

local uninstall
if subfiles then
    local data = "local tbl = " .. assert(serialization.serialize(subfiles)) .. "\n"
    data = data .. [[
local fs = require("filesystem")
local su = require("superUtiles")

local thisDrive = fs.get(su.getPath())

for i, v in ipairs(tbl) do
    print("removing file", v, "ok", thisDrive.remove(v))
end

fs.remove(su.getPath())
    ]]
    uninstall = data
elseif fromProxy.exists("/.uninstall") then
    uninstall = assert(su.getFile(fs.concat(su.getMountPoint(from), ".uninstall")))
end

if uninstall then
    su.saveFile(fs.concat(su.getMountPoint(target), "free/uninstallers", driveName), uninstall)
end