local robot = require("robot")
local event = require("event")
local shell = require("shell")
local component = require("component")
local unicode = require("unicode")

---------------------------------------

local modem = component.modem
local args = shell.parse(...)
local port = tonumber(args[1])
modem.open(port or error("port is nil"))

---------------------------------------

local side = "front"

local function main()
    while true do
        local _, _, _, _, _, _, command, arg1 = event.pull("modem_message", modem.address, nil, port, nil, "robotCommand")
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

while true do
    local ok, err = pcall(main)
    if not ok then
        local str = "interrupt"
        if unicode.sub(err, 1, unicode.len(str)) == str then return end
        print("err: "..(err or "unkown"))
    end
end