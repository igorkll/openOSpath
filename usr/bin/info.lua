local event = require("event")
local su = require("superUtiles")
local component = require("component")
local unicode = require("unicode")
local computer = require("computer")
local serialization = require("serialization")
local internet = component.isAvailable("internet") and component.internet

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

local outData
if internet then
    outData = assert(serialization.unserialize(assert(getInternetFile(url.."/version.cfg"))))
end
local inData = assert(serialization.unserialize(assert(su.getFile("/version.cfg"))))

--------------------------------------------------

if outData then
    print("информациа о обновлении ("..tostring(outData.version).."):")
    print(outData.info or "отсутствует")
end
print("информациа о устоновленной версии ("..tostring(inData.version).."):")
print(inData.info or "отсутствует")