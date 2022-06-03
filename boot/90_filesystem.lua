local event = require("event")
local fs = require("filesystem")
local shell = require("shell")
local tmp = require("computer").tmpAddress()
local computer = require("computer")
local su = require("superUtiles")

local pendingAutoruns = {}

local function autorun(_, address)
    if _G.recoveryMod then return end
    local proxy = fs.proxy(address)
    local name
    for lfs, path in fs.mounts() do
        if address == lfs.address then
            name = path
            break 
        end
    end
    if not name then return end
    if (not fs.exists("/etc/filesystem.cfg") or fs.isAutorunEnabled()) and (address ~= fs.get("/").address) and (tmp ~= address) and _G.externalAutoruns then
        local function run(file)
            if file then
                local run = {file, nil, proxy}
                if pendingAutoruns then
                    table.insert(pendingAutoruns, run)
                else
                    xpcall(shell.execute, event.onError, table.unpack(run))
                end
            end
        end
        run(shell.resolve(fs.concat(name, ".autorun"), "lua"))
        run(shell.resolve(fs.concat(name, "autorun"), "lua"))
    end
end

local function onComponentAdded(_, address, componentType)
    if not _G.filesystemsInit then return end
    if componentType == "filesystem" and tmp ~= address then
        local proxy = fs.proxy(address)
        if proxy then
            local name = address:sub(1, 3)
            while fs.exists(fs.concat("/mnt", name)) and name:len() < address:len() -- just to be on the safe side
            do
                name = address:sub(1, name:len() + 1)
            end

            local freeMountPath = fs.concat("/free/allMounts", name)
            fs.mount(proxy, freeMountPath)

            local perm = su.getPerms(proxy)
            if not perm.doNotMount or address == fs.get("/") then
                fs.mount(proxy, fs.concat("/mnt", name))
            end

            if not perm.doNotIndex and address ~= fs.get("/") and not _G.recoveryMod then
                local pathsTbl = perm.indexPaths or {"/home/bin", "/usr/bin"}
                for i, v in ipairs(pathsTbl) do
                    shell.setPath(shell.getPath() .. ":" .. fs.concat(freeMountPath, v))
                end
            end
            
            autorun(_, address)
        end
    end
end

local function onComponentRemoved(_, address, componentType)
    if componentType == "filesystem" then
        if fs.get("/").address == address then
            computer.shutdown()
        elseif fs.get(shell.getWorkingDirectory()).address == address then
            shell.setWorkingDirectory(os.getenv("HOME") or "/")
        end
        fs.umount(address)
    end
end

event.listen("init", function()
    for _, run in ipairs(pendingAutoruns) do
        xpcall(shell.execute, event.onError, table.unpack(run))
    end
    pendingAutoruns = nil
    return false
end)

event.listen("component_added", onComponentAdded)
--event.listen("autorun", autorun)
event.listen("component_removed", onComponentRemoved)

require("package").delay(fs, "/lib/core/full_filesystem.lua")