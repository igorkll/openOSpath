local gui = require("gui_new").create()
local event = require("event")
local component = require("component")

local modem = component.modem

----------------------------------------------

local port = nil

local function splas()
    gui.splas("выберите порт")
end

local side = "front"
local function send(...)
    if port ~= 0 then
        if not port then splas() return end
        modem.broadcast(port, "robotCommand",  ...)
    else
        local command, arg1 = ...
        local robot = require("robot")
        if command == "forward" then
            robot.forward()
        elseif command == "back" then
            robot.back()
        elseif command == "turnLeft" then
            robot.turnLeft()
        elseif command == "turnRight" then
            robot.turnRight()
        elseif command == "up" then
            robot.up()
        elseif command == "down" then
            robot.down()
        elseif command == "place" then
            if side == "up" then
                robot.placeUp()
            elseif side == "down" then
                robot.placeDown()
            elseif side == "front" then
                robot.place()
            end
        elseif command == "swing" then
            if side == "up" then
                robot.swingUp()
            elseif side == "down" then
                robot.swingDown()
            elseif side == "front" then
                robot.swing()
            end
        elseif command == "side" then
            side = arg1
        elseif command == "slot" then
            robot.select(arg1)
        elseif command == "rs" then
            if component.isAvailable("redstone") then
                for i = 0, 5 do
                    component.redstone.setOutput(i, (arg1 and 15) or 0)
                end
            end
        elseif command == "suck" then
            if side == "up" then
                robot.suckUp(math.huge)
            elseif side == "down" then
                robot.suckDown(math.huge)
            elseif side == "front" then
                robot.suck(math.huge)
            end
        elseif command == "suckALL" then
            if side == "up" then
                while robot.suckUp(math.huge) do end
            elseif side == "down" then
                while robot.suckDown(math.huge) do end
            elseif side == "front" then
                while robot.suck(math.huge) do end
            end
        elseif command == "drop" then
            if side == "up" then
                robot.dropUp(math.huge)
            elseif side == "down" then
                robot.dropDown(math.huge)
            elseif side == "front" then
                robot.drop(math.huge)
            end
        elseif command == "dropALL" then
            if side == "up" then
                for i = 1, robot.inventorySize() do robot.select(i) robot.dropUp(math.huge) end
            elseif side == "down" then
                for i = 1, robot.inventorySize() do robot.select(i) robot.dropDown(math.huge) end
            elseif side == "front" then
                for i = 1, robot.inventorySize() do robot.select(i) robot.drop(math.huge) end
            end
        end
    end
end

local function getPos(x, y)
    return ((x - 1) * 8) + 1, ((y - 1) * 4) + 1
end

local main = gui.createScene(0, 8 * 6, 4 * 3)
local x, y = getPos(1, 1)
main.createInputBox(x, y, 8, 4, "port", 0x0000FF, 0xFFFFFF, function(input)
    port = tonumber(input)
    if port == 0 then 
        if not component.isAvailable("robot") then
            gui.splas("для упр рбт на примую пргрмм длжн бть зпшн на рбт")
            port = nil
            return
        end
    end
    if not port then gui.splas("неверные данные") end
end)
local x, y = getPos(1, 3)
main.createButton(x, y, 8, 4, "side", 0xFFAA00, 0xFFFFFF, false, nil, nil, nil, function(input)
    local selected = gui.context(true, 1, 1, {"up", "front", "down"}, true)
    if selected then
        send("side", selected)
    end
end)
local x, y = getPos(2, 2)
main.createButton(x, y, 8, 4, "redstone", 0xFF0000, 0xFFFFFF, true, false, 0xAA0000, 0xAAAAAA, function(state) send("rs", state) end)
local x, y = getPos(3, 1)
main.createButton(x, y, 8, 4, "swing", 0xFF00FF, 0xFFFFFF, false, nil, nil, nil, function() send("swing") end)
local x, y = getPos(3, 3)
main.createButton(x, y, 8, 4, "place", 0xFF00FF, 0xFFFFFF, false, nil, nil, nil, function() send("place") end)
local x, y = getPos(4, 2)
main.createInputBox(x, y, 8, 4, "slot", 0x00FFFF, 0xFFFFFF, function(input)
    local data = tonumber(input)
    if not data then 
        gui.splas("неверные данные")
        return
    end
    send("slot", data)
end)

local x, y = getPos(2, 1)
local forward = main.createButton(x, y, 8, 4, "forward", 0x00FF00, 0xFFFFFF, false, nil, nil, nil, function() send("forward") end)
local x, y = getPos(2, 3)
local back = main.createButton(x, y, 8, 4, "back", 0x00FF00, 0xFFFFFF, false, nil, nil, nil, function() send("back") end)
local x, y = getPos(1, 2)
local left = main.createButton(x, y, 8, 4, "left", 0x00FF00, 0xFFFFFF, false, nil, nil, nil, function() send("turnLeft") end)
local x, y = getPos(3, 2)
local rigth = main.createButton(x, y, 8, 4, "right", 0x00FF00, 0xFFFFFF, false, nil, nil, nil, function() send("turnRight") end)
local x, y = getPos(4, 1)
local up = main.createButton(x, y, 8, 4, "up", 0x00FF00, 0xFFFFFF, false, nil, nil, nil, function() send("up") end)
local x, y = getPos(4, 3)
local down = main.createButton(x, y, 8, 4, "down", 0x00FF00, 0xFFFFFF, false, nil, nil, nil, function() send("down") end)

local x, y = getPos(5, 1)
local down = main.createButton(x, y, 8, 4, "suck", 0xFFFFFF, 0, false, nil, nil, nil, function() send("suck") end)
local x, y = getPos(5, 2)
local down = main.createButton(x, y, 8, 4, "drop", 0xFFFFFF, 0, false, nil, nil, nil, function() send("drop") end)
local x, y = getPos(5, 3)
local down = main.createButton(x, y, 8, 4, "suckALL", 0xFFFFFF, 0, false, nil, nil, nil, function() send("suckALL") end)
local x, y = getPos(6, 1)
local down = main.createButton(x, y, 8, 4, "dropALL", 0xFFFFFF, 0, false, nil, nil, nil, function() send("dropALL") end)



gui.select(main)

----------------------------------------------

while true do
    while true do
        local eventData = {event.pull(0.5)}
        gui.uploadEvent(table.unpack(eventData))
    end
end