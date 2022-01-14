apis = {}

apis.bootloaderspath = "/bios/bootloaders/"
apis.apispath = "/bios/apis.lua"
apis.mainpath = "/bios/main.lua"
apis.configspaths = "/bios/configs/"
apis.datapaths = "/bios/data/"
apis.loaderpath = "/bios/data/loader.lua"
apis.utilitespath = "/bios/utilites/"

apis.biospasswordcfgpath = apis.configspaths.."biospassword"
apis.bootpasswordcfgpath = apis.configspaths.."bootpassword"
apis.resolutionAspectRatioMode = apis.configspaths.."useaspectratio"
apis.biosresolutioncfgpath = apis.configspaths.."biosresolution"
apis.addresscfgpath = apis.configspaths.."address"
apis.bootloadercfgpath = apis.configspaths.."bootloader"
apis.notselectmenu = apis.configspaths.."notselectmenu"

apis.computerlink = apis.configspaths.."computerlink"
apis.eepromlink = apis.configspaths.."eepromlink"
apis.eepromchecksumlink = apis.configspaths.."eepromchecksumlink"
apis.drivelink = apis.configspaths.."drivelink"

apis.donotautolink = apis.datapaths.."donotautolink"

apis.servicecodepath = apis.configspaths.."servicecode"
apis.keypath = apis.configspaths.."bioskey"

apis.themepath = apis.configspaths.."theme"

apis.autorunpath = apis.configspaths.."autorun.lua"
apis.mainautorunpath = apis.datapaths.."autorun.lua"

---------------------------------------------------------------------------------

apis.biosaddress = computer.getBiosAddress()
apis.back = 0xFFFFFF
apis.fore = 0x000000
apis.fs = component.proxy(apis.biosaddress)

function apis.runbootscript(data, ...)
    local code, err = load(data, "=bootloader")
    if not code then
        return nil, "bootloader load err: "..(err or "unkown")
    else
        local ok, err = xpcall(code, debug.traceback, ...)
        if not ok then
            return nil, "bootloader run err: "..(err or "unkown")
        else
            if not err then
                return nil, "system in not available"
            end
            apis.boot(err)
        end
    end
end

function apis.getfile(path)
    local fs = apis.fs
    local buffer = ""

    local file, err = fs.open(path)
    if not file then
        return nil, err
    end
    while true do
        local read = fs.read(file, math.huge)
        if not read then
            break
        end
        buffer = buffer .. read
    end
    fs.close(file)

    return buffer
end

function apis.savefile(path, data)
    local fs = apis.fs
    local file, err = fs.open(path, "w")
    if not file then
        return nil, err
    end
    fs.write(file, data)
    fs.close(file)
end

--apis.nextchunkname
function apis.runscript(data, ...)
    local code, err = load(data, apis.nextchunkname)
    apis.nextchunkname = nil
    if not code then
        return nil, err or "unkown"
    else
        return xpcall(code, debug.traceback, ...)
    end
end

function apis.dofile(path, ...)
    apis.nextchunkname = path
    local data, err = apis.getfile(path)
    if not data then
        return nil, err
    end
    return apis.runscript(data, ...)
end

-----------------------------------------------


local function check()
    local eeprom = component.list("eeprom")()
    if not component.proxy(eeprom or "") then
        error("not eeprom found")
    end
    if apis.fs.exists(apis.computerlink) and apis.getfile(apis.computerlink) ~= computer.address() then
        error("computer is not original")
    end
    if apis.fs.exists(apis.eepromlink) and apis.getfile(apis.eepromlink) ~= component.list("eeprom")() then
        error("eeprom is not original")
    end
    if apis.fs.exists(apis.drivelink) and apis.getfile(apis.eepromchecksumlink) ~= component.proxy(component.list("eeprom")()).getChecksum() then
        error("uncorrect checksum")
    end
    if apis.fs.exists(apis.eepromchecksumlink) and apis.getfile(apis.drivelink) ~= apis.biosaddress then
        error("uncorrect drive")
    end
end

if not apis.fs.exists(apis.donotautolink) then
    if not apis.fs.exists(apis.computerlink) then
        apis.savefile(apis.computerlink, computer.address())
    end
    if not apis.fs.exists(apis.eepromlink) then
        apis.savefile(apis.eepromlink, component.list("eeprom")())
    end
    if not apis.fs.exists(apis.drivelink) then
        apis.savefile(apis.drivelink, apis.biosaddress)
    end
    apis.reChecksum = function()
        apis.savefile(apis.eepromchecksumlink, component.proxy(component.list("eeprom")()).getChecksum())
    end
    if not apis.fs.exists(apis.eepromchecksumlink) then
        apis.reChecksum()
    end
end

check()

assert(apis.dofile(apis.apispath))
assert(apis.dofile(apis.mainpath))