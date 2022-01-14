local gui = require("gui_new").create()
local event = require("event")
local bigchat = require("bigchat")
local computer = require("computer")
local su = require("superUtiles")
local keyboard = require("keyboard")
local shell = require("shell")

local args, options = shell.parse(...)
local appkey = args[2] or "public chat"
local usercode = args[1] or su.generateRandomID()
local rx, ry = gui.gpu.getResolution()

---------------------------------------------

gui.exitcallbacks[#gui.exitcallbacks + 1] = function()
    if not options.a then
        bigchat.send(appkey, usercode..": вышел")
    end
end

local main = gui.createScene()
local log = main.createLogZone(1, 1, rx, ry - 3)
local input = main.createInputBox(1, ry - 2, rx - 10, 3, "input", nil, nil, function(str)
    str = usercode..": "..str
    log.add(str)
    bigchat.send(appkey, str)
end)
local exitPlus = main.createButton(rx - 10, ry - 2, 11, 3, "crypto exit", nil, nil, nil, nil, nil, nil, function()
    options.a = true
    gui.exit()
end)

gui.select(main)

---------------------------------------------

log.add("ваш id: "..usercode)

if not options.n then
    bigchat.send(appkey, usercode..": присоенденился")
    log.add("сообшения о вашем входе отправлено")
else
    log.add("сообшения о вашем входе НЕ отправлено")
end

if not options.a then
    log.add("сообшения о вашем выходе БУДЕТ отправлено")
else
    log.add("сообшения о вашем выходе НЕ будет отправлено")
end

---------------------------------------------

while true do
    local eventData = {event.pull(0.2)}
    gui.uploadEvent(table.unpack(eventData))
    if eventData[1] == "big_chat" and eventData[2] == appkey then
        log.add(eventData[3])
        computer.beep()
    end
    if keyboard.isAltDown() then
        input.input()
    end
end