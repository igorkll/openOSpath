local event = require("event")
local su = require("superUtiles")
local component = require("component")
local unicode = require("unicode")
local computer = require("computer")
local serialization = require("serialization")
if not component.isAvailable("internet") then
    print("internet card is not found")
    return
end
local internet = component.internet
local term = require("term")
local thread = require("thread")

--------------------------------------------------

local url = "https://raw.githubusercontent.com/igorkll/openOSpath/main"

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

local outData = assert(serialization.unserialize(assert(getInternetFile(url.."/version.cfg"))))
local inData = assert(serialization.unserialize(assert(su.getFile("/version.cfg"))))

--------------------------------------------------

if outData.version > inData.version then
    if term.isAvailable() then
        local gui = require("simpleGui2").create()

        thread.create(function()
            while true do
                gui.status("работая с обновлениями")
                os.sleep(2)
                gui.status("пожалуйста, не выключайте устройство")
                os.sleep(2)
                gui.status("обновления устанавливаеться автоматически")
                os.sleep(2)
            end
        end)
    end
    os.execute("wget https://raw.githubusercontent.com/igorkll/fastOS/main/getinstaller.lua /tmp/getinstaller.lua -f -Q")
    os.execute("/tmp/getinstaller https://raw.githubusercontent.com/igorkll/openOSpath/main / -q")
    computer.shutdown(true)
end
os.exit()