local gui = require("gui_new").create()
local midi = require("midi2")
local fs = require("filesystem")
local event = require("event")
local component = require("component")

-----------------------------------------------

local tones = {}
local device = {}

for i = 1, component.noise.channel_count do
    local function channel(n,d)
        tones[i] = {n,d}
    end
    device[i] = channel
end

local function flush()
    component.noise.play(tones)
    tones = {}
end
device.flush = flush

local obj
local objthread

-----------------------------------------------

local main = gui.createScene()
local name = main.createLabel(10, 1, 32, 1, "name")
local selectButton = main.createButton(1, 1, 8, 1, "select", nil, nil, nil, nil, nil, nil, function()
    local files = {}
    local midipath = "/usr/midi"
    for data in fs.list(midipath) do
        files[#files + 1] = data
    end
    local selected = gui.context(true, 1, 1, files, true)
    if selected then
        obj = midi.create(fs.concat(midipath, selected), device)
        obj.min = 20
        obj.max = 2000
        name.text = selected
        name.draw()
    end
end)
local playButton = main.createButton(1, 2, 8, 1, "play", nil, nil, nil, nil, nil, nil, function()
    if objthread then objthread:kill() objthread = nil end 
    if obj and not objthread then objthread = obj.createThread(true) end
end)
local stopButton = main.createButton(1, 3, 8, 1, "stop", nil, nil, nil, nil, nil, nil, function()
    if objthread then objthread:kill() objthread = nil end
end)

local speed = main.createSeekBar(11, 4, 24, nil, nil, 0.1, 2, 1)
local notespeed = main.createSeekBar(11, 5, 24, nil, nil, 0.1, 2, 1)
local pitch = main.createSeekBar(11, 6, 24, nil, nil, 0.1, 2, 1)

local speedlabel = main.createLabel(1, 4, 10, 1, "speed")
local notespeedlabel = main.createLabel(1, 5, 10, 1, "notespeed")
local pitchlabel = main.createLabel(1, 6, 10, 1, "pitch")

local speedlabelvalue = main.createLabel(25 + 10, 4, 10, 1, "")
local notespeedlabelvalue = main.createLabel(25 + 10, 5, 10, 1, "")
local pitchlabelvalue = main.createLabel(25 + 10, 6, 10, 1, "")

local function textConstructor(num)
    return "channel: "..tostring(num)..", "..tostring(component.noise.getMode(num))
end

local modeButtons = {}
for i = 1, component.noise.channel_count do
    local button = main.createButton(1, 6 + i, 16, 1, textConstructor(i))
    button.callbacks[#button.callbacks + 1] = function()
        local _, num = gui.context(true, 18, 6 + i, {"  1  ", "  2  ", "  3  ", "  4  "}, true)
        if num then
            component.noise.setMode(i, num)
            button.text = textConstructor(i)
            button.draw()
        end
    end
    modeButtons[i] = button
end

local setAllModes = main.createButton(1, 15, 11, 1, "setAllModes")
local function callback()
    local _, num = gui.context(true, 13, 15, {"  1  ", "  2  ", "  3  ", "  4  "})
    if num then
        for i = 1, component.noise.channel_count do
            component.noise.setMode(i, num)
            modeButtons[i].text = textConstructor(i)
            modeButtons[i].draw()
        end
    end
end
setAllModes.callbacks[#setAllModes.callbacks + 1] = callback

gui.select(1)

-----------------------------------------------

while true do
    local eventData = {event.pull(0.5)}
    gui.uploadEvent(table.unpack(eventData))
    if obj then
        obj.speed = speed.getState()
        obj.noteduraction = notespeed.getState()
        obj.pitch = pitch.getState()
    end
    speedlabelvalue.text = tostring(math.floor(speed.getState() * 9) / 8)
    notespeedlabelvalue.text = tostring(math.floor(notespeed.getState() * 9) / 8)
    pitchlabelvalue.text = tostring(math.floor(pitch.getState() * 9) / 8)
    speedlabelvalue.draw()
    notespeedlabelvalue.draw()
    pitchlabelvalue.draw()
end