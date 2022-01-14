local lib = {}

function lib.soundPull(sound)
    sound.createThread()
end

function lib.createSoundCore()
    local obj = {}

    obj.stop = function()
        if obj.thread then
            obj.thread:kill()
            obj.thread = nil
        end
    end

    obj.select = function(midi, loop)
        obj.stop()
        obj.thread = midi.createThread(loop or true)
    end

    return obj
end

return lib