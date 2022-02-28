local shell = require("shell")
local tty = require("tty")
local text = require("text")
local sh = require("sh")
local event = require("event")
local term = require("term")

----------------------------------

local args = shell.parse(...)

shell.prime()

----------------------------------

if #args == 0 then
    local function shortcut(_, uuid, _, code)
        if uuid == term.keyboard() and code == 29 then
            event.push("interrupted", 1)
            event.push("clipboard", uuid, "shortcut\n", "system")
        end
    end

    local has_profile
    local input_handler = {hint = sh.hintHandler}
    while true do
      if io.stdin.tty and io.stdout.tty then
            if not has_profile then
            has_profile = true
            dofile("/etc/profile.lua")
          end
          if tty.getCursor() > 1 then
            io.write("\n")
          end
          io.write(sh.expand(os.getenv("PS1") or "$ "))
      end
      tty.window.cursor = input_handler
        event.listen("key_down", shortcut)
      local command = io.stdin:readLine(false)
        event.ignore("key_down", shortcut)
      tty.window.cursor = nil
      if command then
          command = text.trim(command)
          if command == "exit" then
            return
          elseif command ~= "" then
                local result, reason = sh.execute(_ENV, command)
                if not result then
                    io.stderr:write((reason and tostring(reason) or "unknown error") .. "\n")
                end
          end
        elseif command == nil then
            return
        end
    end
else
    local result = table.pack(sh.execute(...))
    if not result[1] then
      error(result[2], 0)
    end
    return table.unpack(result, 2)
end