local su = require("superUtiles")
local event = require("event")

-----------------------------------------

local serialization = {}

-- delay loaded tables fail to deserialize cross [C] boundaries (such as when having to read files that cause yields)
local local_pairs = function(tbl)
    local mt = getmetatable(tbl)
    return (mt and mt.__pairs or pairs)(tbl)
end

-- Important: pretty formatting will allow presenting non-serializable values
-- but may generate output that cannot be unserialized back.
function serialization.serialize(value, pretty, netw, isMt)
    local networks = require("networks")
    local network = assert(networks.getNetwork(netw))
    local kw = {
        ["and"] = true,
        ["break"] = true,
        ["do"] = true,
        ["else"] = true,
        ["elseif"] = true,
        ["end"] = true,
        ["false"] = true,
        ["for"] = true,
        ["function"] = true,
        ["goto"] = true,
        ["if"] = true,
        ["in"] = true,
        ["local"] = true,
        ["nil"] = true,
        ["not"] = true,
        ["or"] = true,
        ["repeat"] = true,
        ["return"] = true,
        ["then"] = true,
        ["true"] = true,
        ["until"] = true,
        ["while"] = true
    }
    local id = "^[%a_][%w_]*$"
    local ts = {}
    local result_pack = {}
    local function recurse(current_value, depth, mtname, mtt)
        interrupt()
        --[[
        local vmt = getmetatable(current_value)
        if type(vmt) == "table" then
            if vmt.__call then
                local old_current_value = current_value
                current_value = function(...)
                    return old_current_value(...)
                end
            end
        end
        ]]
        local t = type(current_value)
        if t == "number" then
            if current_value ~= current_value then
                table.insert(result_pack, "0/0")
            elseif current_value == math.huge then
                table.insert(result_pack, "math.huge")
            elseif current_value == -math.huge then
                table.insert(result_pack, "-math.huge")
            else
                table.insert(result_pack, tostring(current_value))
            end
        elseif t == "string" then
            table.insert(result_pack, (string.format("%q", current_value):gsub("\\\n", "\\n")))
        elseif
            t == "nil" or t == "boolean" or pretty and ((t ~= "table" and t ~= "userdata") or (getmetatable(current_value) or {}).__tostring)
         then
            table.insert(result_pack, tostring(current_value))
        elseif t == "table" or t == "userdata" then
            if ts[current_value] then
                if pretty then
                    table.insert(result_pack, "recursion")
                    return
                else
                    table.insert(result_pack, "nil")
                    return
                    --error("tables with cycles are not supported")
                end
            end
            ts[current_value] = true
            local f, vmt
            if pretty then
                local ks, sks, oks = {}, {}, {}
                for k in local_pairs(current_value) do
                    interrupt()
                    if type(k) == "number" then
                        table.insert(ks, k)
                    elseif type(k) == "string" then
                        table.insert(sks, k)
                    else
                        table.insert(oks, k)
                    end
                end
                table.sort(ks)
                table.sort(sks)
                for _, k in ipairs(sks) do
                    interrupt()
                    table.insert(ks, k)
                end
                for _, k in ipairs(oks) do
                    interrupt()
                    table.insert(ks, k)
                end
                local n = 0
                f =
                    table.pack(
                    function()
                        n = n + 1
                        local k = ks[n]
                        if k ~= nil then
                            return k, current_value[k]
                        else
                            return nil
                        end
                    end
                )
            else
                f = table.pack(local_pairs(current_value))
                vmt = getmetatable(current_value)
                if type(vmt) == "table" then
                    table.insert(result_pack, "setmetatable(")
                else
                    vmt = nil
                end
            end
            local i = 1
            local first = true
            table.insert(result_pack, "{")
            for k, v in table.unpack(f) do
                interrupt()
                if not first then
                    table.insert(result_pack, ",")
                    if pretty then
                        table.insert(result_pack, "\n" .. string.rep(" ", depth))
                    end
                end
                first = nil
                local tk = type(k)
                if tk == "number" and k == i then
                    i = i + 1
                    recurse(v, depth + 1, k, isMt)
                else
                    if tk == "string" and not kw[k] and string.match(k, id) then
                        table.insert(result_pack, k)
                    else
                        table.insert(result_pack, "[")
                        recurse(k, depth + 1, k, isMt)
                        table.insert(result_pack, "]")
                    end
                    table.insert(result_pack, "=")
                    recurse(v, depth + 1, k, isMt)
                end
            end
            ts[current_value] = nil -- allow writing same table more than once
            table.insert(result_pack, "}")
            if vmt then
                table.insert(result_pack, ",")
                table.insert(result_pack, serialization.serialize(vmt, pretty, netw, current_value))
                table.insert(result_pack, ")")
            end
        elseif t == "function" then
            local id = su.generateRandomID()
            event.listen("network_message", function(_, netw2, id2, side, ...)
                if side == "call" and netw2 == netw and id2 == id then
                    local ret
                    if isMt and mtname == "__call" then
                        local args = {...}
                        ret = {pcall(isMt, su.unpack(args, 2))}
                    else
                        ret = {pcall(current_value, ...)}
                    end
                    network.send(id, "ret", ret)
                end
            end)
            table.insert(result_pack, "function() return '" .. netw .. "', '" .. id .. "' end")
        else
            error("unsupported type: " .. t)
        end
    end
    recurse(value, 1)
    local result = table.concat(result_pack)
    if pretty then
        local limit = type(pretty) == "number" and pretty or 32
        local truncate = 0
        while limit > 0 and truncate do
            interrupt()
            truncate = string.find(result, "\n", truncate + 1, true)
            limit = limit - 1
        end
        if truncate then
            return result:sub(1, truncate) .. "..."
        end
    end
    return result
end

function serialization.unserialize(data)
    checkArg(1, data, "string")
    local networks = require("networks")

    local result, reason = load("return " .. data, "=data", nil, {math = {huge = math.huge}, setmetatable = setmetatable})
    if not result then
        return nil, reason
    end
    local ok, output = pcall(result)
    if not ok then
        return nil, output
    end
    local function recurse(tbl)
        local mt = getmetatable(tbl)
        if type(mt) == "table" then recurse(mt) end

        for k, v in pairs(tbl) do
            if type(v) == "function" then
                local netw, id = v()
                if type(netw) == "string" and type(id) == "string" then
                    local network = networks.getNetwork(netw)
                    if network then
                        tbl[k] = function(...)
                            network.send(id, "call", ...)
                            local ret = {event.pull(4, "network_message", netw, id, "ret")}
                            if type(ret[5]) == "table" then
                                if ret[5][1] then
                                    return su.unpack(ret[5], 2)
                                else
                                    error(ret[5][2], 0)
                                end
                            else
                                error("no connection", 0)
                            end
                        end
                    end
                end
            elseif type(v) == "table" then
                recurse(v)
            end
        end
    end
    local ok, err = pcall(recurse, output)
    if not ok then
        return nil, err
    end
    return output
end

return serialization
