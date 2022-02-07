local gui = require("gui_new").create(50, 16)
local event = require("event")
local component = require("component")
local computer = require("computer")

------------------------------------------------------------------------------------------

local tapeaddress

------------------------------------------------------------------------------------------

local function selector()
    local addresses = {}
    local names = {}
    for address in component.list("tape_drive") do
        addresses[#addresses + 1] = address
        names[#names + 1] = address:sub(1, 8)
    end
    names[#names + 1] = "clear"
    local _, num = gui.context(true, 43, 1, names)
    if num then
        if num > #addresses then
            tapeaddress = nil
        end
        tapeaddress = addresses[num]
    end
end

local function seektape(num)
    if not tapeaddress then
        return
    end
    local tape = component.proxy(tapeaddress)
    if not tape then
        return
    end
    if tape.getState() == "STOPPED" then
        tape.seek(num)
    else
        tape.stop()
        tape.seek(num)
        tape.play()
    end
end

local function seekforwardFunction()
    seektape(5 * 10000)
end

local function seekbackFunction()
    seektape(-5 * 10000)
end

local function play()
    if not tapeaddress then
        return
    end
    local tape = component.proxy(tapeaddress)
    if not tape then
        return
    end
    tape.play()
end

local function stop()
    if not tapeaddress then
        return
    end
    local tape = component.proxy(tapeaddress)
    if not tape then
        return
    end
    tape.stop()
end

local function rewind()
    if not tapeaddress then
        return
    end
    local tape = component.proxy(tapeaddress)
    if not tape then
        return
    end
    local ok = gui.yesno("вы уверенны что хотите отмотать ленту?")
    if ok then
        seektape(-tape.getSize())
    end
end

local function restate(new, old)
    if not tapeaddress then
        return
    end
    local tape = component.proxy(tapeaddress)
    if not tape then
        return
    end
    seektape(new - old)
end

------------------------------------------------------------------------------------------

local main = gui.createScene()
local selected = main.createLabel(1, 1, 32, 1, ".")
local state = main.createLabel(1, 2, 32, 1, "null")

local select = main.createButton(34, 1, 8, 2, "select", nil, nil, nil, nil, nil, nil, selector)

local seekback = main.createButton(1, 4, 8, 2, "back", nil, nil, nil, nil, nil, nil, seekbackFunction)
local play = main.createButton(10 * 1, 4, 8, 2, "play", nil, nil, nil, nil, nil, nil, play)
local stop = main.createButton(10 * 2, 4, 8, 2, "stop", nil, nil, nil, nil, nil, nil, stop)
local seekforward = main.createButton(10 * 3, 4, 8, 2, "forwrd", nil, nil, nil, nil, nil, nil, seekforwardFunction)
local rewind = main.createButton(10 * 4, 4, 8, 2, "rewind", nil, nil, nil, nil, nil, nil, rewind)

local autorewind = main.createButton(1, 3 + 4, 10, 2, "autorewind", nil, nil, true)
local alltapes = main.createButton(12, 3 + 4, 10, 2, "alltapes", nil, nil, true)

local speedlabel = main.createLabel(1, 10, 6, 1, "1")
local speed = main.createSeekBar(7, 10, 16, nil, nil, 0.5, 2, 1)

local volumelabel = main.createLabel(1, 11, 6, 1, "1")
local volume = main.createSeekBar(7, 11, 16, nil, nil, 0.1, 1, 1)

local seek = main.createSeekBar(1, 13, 50, nil, nil, 0, 0, 0, true, 0, restate)
gui.select(main)

------------------------------------------------------------------------------------------

while true do
    local eventData = {event.pull(0.05)}
    gui.uploadEvent(table.unpack(eventData))
    
    local nSpeed = speed.getState()
    speedlabel.text = tostring(nSpeed)
    speedlabel.draw()

    local nVolume = volume.getState()
    volumelabel.text = tostring(nVolume)
    volumelabel.draw()

    if tapeaddress and component.proxy(tapeaddress) then
        local tape = component.proxy(tapeaddress)

        seek.max = tape.getSize()
        seek.setState(tape.getPosition())

        local nSpeed = speed.getState()
        tape.setSpeed(nSpeed)

        local nVolume = volume.getState()
        tape.setVolume(nVolume)

        selected.text = tapeaddress:sub(1, 16)
        state.text = tape.getState()

        selected.draw()
        state.draw()

        if tape.getState() == "STOPPED" and autorewind.getState() and not alltapes.getState() then
            seektape(-tape.getSize())
            tape.play()
        end
    else
        tapeaddress = nil

        selected.text = "."
        state.text = "null"

        selected.draw()
        state.draw()
    end
    if autorewind.getState() and alltapes.getState() then
        for data in component.list("tape_drive") do
            local tape = component.proxy(data)
            if tape.getState() == "STOPPED" then
                tape.seek(-tape.getSize())
                tape.play()
            end
        end
    end
end