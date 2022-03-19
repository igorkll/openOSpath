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
    os.execute("wget https://raw.githubusercontent.com/igorkll/fastOS/main/getinstaller.lua /tmp/getinstaller.lua -f && /tmp/getinstaller https://raw.githubusercontent.com/igorkll/openOSpath/main /")
    computer.shutdown(true)
end