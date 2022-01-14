local function bootTo(address, bootloader)
    local proxy, err = component.proxy(address)
    if not proxy then
        return nil, err
    end
    if bootloader == "" then
        bootloader = nil
    end
    local bootloaderpath = apis.bootloaderspath .. (bootloader or proxy.type)
    if not apis.fs.exists(bootloaderpath) then
        return nil, "not this bootloader"
    end
    local bootloader, err = apis.getfile(bootloaderpath)
    if not bootloader then
        return nil, err
    end
    return apis.runbootscript(bootloader, address, apis.biosaddress)
end

local function bootToWrap(address, bootloader)
    --local ok, err = xpcall(function(address, bootloader) return assert(bootTo(address, bootloader)) end, debug.traceback, address, bootloader or apis.getBootloaderName())
    local ok, err = bootTo(address, bootloader or apis.getBootloaderName())
    apis.splash(err or "unkown")
    return ok, err
end

local function parseComponents(filter)
    local names = {}
    local addresses = {}
    local types = {}
    for address, type in component.list(filter) do
        addresses[#addresses + 1] = address
        types[#types + 1] = type
        names[#names + 1] = address:sub(1, 8)..":"..type
        local proxy = component.proxy(address)
        if proxy.getLabel and proxy.getLabel() and proxy.getLabel() ~= "" then
            names[#names] = names[#names]..":"..proxy.getLabel()
        end
    end
    return names, addresses, types
end
apis.parseComponents = parseComponents

--------------------------------------------

local function selectbootcomponent()
    local names, addresses, types = parseComponents()
    local bootcomponent = apis.getBootAddress()
    local num
    if bootcomponent ~= "" and component.proxy(bootcomponent) then
        for i = 1, #addresses do
            if addresses[i] == bootcomponent then
                num = i + 2
                break
            end
        end
    end
    local select = apis.select({"select component", "back", "clear", table.unpack(names)}, num)
    if select == 1 then
        return
    elseif select == 2 then
        return ""
    else
        select = select - 2
        return addresses[select]
    end
end

local function selectbootloader()
    local names = apis.fs.list(apis.bootloaderspath)
    local bootcomponent = apis.getBootloaderName()
    local num = 2
    if bootcomponent ~= "" then
        for i = 1, #names do
            if names[i] == bootcomponent then
                num = i + 2
                break
            end
        end
    end
    local select = apis.select({"select bootloader", "back", "auto", table.unpack(names)}, num)
    if select == 1 then
        return
    elseif select == 2 then
        return false
    else
        select = select - 2
        return names[select]
    end
end

local function selectutilite()
    local names = apis.fs.list(apis.utilitespath)
    local select = apis.select({"select utilete", "back", table.unpack(names)})
    if select == 1 then
        return
    else
        select = select - 1
        return names[select]
    end
end

local function runutilite(name, ...)
    local _, out, out2 = xpcall(function(name, ...) local data = assert(apis.getfile(apis.utilitespath..name)); return assert(apis.runscript(data, ...)) end, debug.traceback, name, ...)
    local result = out2 or out
    if type(result) == "string" then
        apis.splash(result)
    end
end

--------------------------------------------

local function mainmenu()
    if apis.isPassword() and not apis.getBootPasswordState() then
        if not apis.enterPassword("BIOS LOCK") then
            apis.splash("uncorrect password")
            return
        end
    end
    while true do
        local select = apis.select({"main menu", "select boot component", "select bootloader", "fast run", "run utilite", "reboot", "shutdown", "back"})
        if select == 1 then
            local address = selectbootcomponent()
            if address then
                apis.setBootAddress(address)
            end
        elseif select == 2 then
            local name = selectbootloader()
            if name then
                apis.setBootloaderName(name)
            elseif name == false then
                apis.setBootloaderName("")
            end
        elseif select == 3 then
            local address = selectbootcomponent()
            if address then
                local bootloader = selectbootloader()
                if bootloader then
                    bootToWrap(address, bootloader)
                elseif bootloader == false then
                    bootToWrap(address, component.proxy(address).type)
                end
            end
        elseif select == 4 then
            local name = selectutilite()
            if name then
                runutilite(name)
            end
        elseif select == 5 then
            computer.shutdown(true)
        elseif select == 6 then
            computer.shutdown()
        elseif select == 7 then
            return
        end
    end
end

--------------------------------------------

if apis.fs.exists(apis.mainautorunpath) then
    local _, out = apis.runscript(apis.getfile(apis.mainautorunpath))
    apis.splash(tostring(out))
end
if apis.fs.exists(apis.autorunpath) then
    local _, out = apis.runscript(apis.getfile(apis.autorunpath))
    apis.splash(tostring(out))
end

if apis.isPassword() and apis.getBootPasswordState() then
    while not apis.enterPassword("BOOT LOCK") do
        apis.splash("uncorrect password")
    end
end

while true do
    ::tonew::
    local bootaddress = apis.getBootAddress()

    if bootaddress and component.proxy(bootaddress) then
        if apis.gpuexists and (apis.keyboard or apis.touch) and not apis.fs.exists(apis.notselectmenu) then
            apis.view("total memory: "..tostring(computer.totalMemory()).."\n" .. "free memory: "..tostring(computer.freeMemory()).."\n" .. "boot address: "..bootaddress.."\n" .. "boot loader: "..apis.getBootloaderName().."\n" .. "press alt to bios menu\n" .. "press enter to os")
            for i = 1, 80 do
                local eventName, uuid, _, code = computer.pullSignal(0.1)
                if eventName == "key_down" and uuid == apis.keyboard then
                    if code == 56 then
                        mainmenu()
                        goto tonew
                    elseif code == 28 then
                        break
                    end
                elseif eventName == "touch" and uuid == apis.screen.address then
                    if code == 5 then
                        mainmenu()
                        goto tonew
                    elseif code == 6 then
                        break
                    end
                end
            end
        end
        bootToWrap(bootaddress)
    else
        mainmenu()
    end
end