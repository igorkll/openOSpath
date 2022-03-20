local event = require("event")
local su = require("superUtiles")
local component = require("component")
local unicode = require("unicode")
local computer = require("computer")
local serialization = require("serialization")
local shell = require("shell")
local fs = require("filesystem")
if not component.isAvailable("internet") then
    print("internet card is not found")
    return
end
local internet = component.internet
local term = require("term")
local thread = require("thread")

--------------------------------------------------

local args, options = shell.parse(...)
local url = args[1] or systemCfg.updateRepo or "https://raw.githubusercontent.com/igorkll/openOSpath/main"
local versionPath = args[2] or "/version.cfg"

--------------------------------------------------

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

--------------------------------------------------

local outData, inData
if not options.f then
    outData = assert(serialization.unserialize(assert(getInternetFile(url .. versionPath))))
    if fs.exists(versionPath) then
        inData = assert(serialization.unserialize(assert(su.getFile(versionPath))))
    else
        inData = {version = 0}
    end
end

--------------------------------------------------

local threads = {}
local isUpdate = false
if options.f or outData.version > inData.version then
    if term.isAvailable() then
        local gui = require("simpleGui2").create()

        table.insert(threads, thread.create(function()
            while true do
                gui.status("работая с обновлениями")
                os.sleep(2)
                gui.status("пожалуйста, не выключайте устройство")
                os.sleep(2)
                gui.status("обновления устанавливаеться автоматически")
                os.sleep(2)
            end
        end))
    end
    os.execute("wget https://raw.githubusercontent.com/igorkll/fastOS/main/getinstaller.lua /tmp/getinstaller.lua -f -Q")
    os.execute("/tmp/getinstaller " .. url .. " / -q")
    isUpdate = true
end
for _, t in ipairs(threads) do t:kill() end
if isUpdate and not options.n then computer.shutdown(true) end
if isUpdate then term.clear() end
return isUpdate