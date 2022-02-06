local gui = require("gui_new").create()
local bigchat = require("bigchat")
local event = require("event")
local thread = require("thread")
local su = require("superUtiles")
local keyboard = require("keyboard")
local computer = require("computer")
local shell = require("shell")

-------------------------------------------

local gpu = gui.gpu
local rx, ry = gpu.getResolution()

local userCode = su.generateRandomID()
local appName = "chat"

-------------------------------------------

local toMain

local login = gui.createScene()
local userName = login.createInputBox(1, 1, 8, 1, "userName", nil, nil, function(str)
    if str then
        userCode = str
    else
        userCode = su.generateRandomID()
    end
end)
login.createButton(1, 2, 8, 1, "gotoChat", nil, nil, nil, nil, nil, nil, function()
    toMain()
end)


-------------------------------------------

local send

local main = gui.createScene()
local logZone = main.createLogZone(1, 1, rx, ry - 3)
local input = main.createInputBox(1, ry - 2, rx, 3, "input", nil, nil, function(str)
    if str then
        send(str)
    end
end)

function send(str)
    bigchat.send(appName, userCode..": "..str)
    logZone.add(userCode.."(you): "..str)
end

-------------------------------------------

function toMain()
    thread.create(function()
        while true do
            local _, _, message = event.pull("big_chat", appName)
            logZone.add(message)
            computer.beep()
        end
    end)

    thread.create(function()
        while true do
            local eventName, uuid, _, code = event.pull("key_down", gui.keyboard)
            if code == 28 then
                input.input()
            end
            os.sleep()
        end
    end)
    gui.select(main)
    send("присоендинился")
end

gui.select(login)

-------------------------------------------

while true do
    local eventData = {event.pull()}
    gui.uploadEvent(table.unpack(eventData))
end