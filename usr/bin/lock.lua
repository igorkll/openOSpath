local su = require("superUtiles")
local component = require("component")
local computer = require("computer")
local term = require("term")
local serialization = require("serialization")
local fs = require("filesystem")
local event = require("event")
local sha256 = require("sha256lib").sha256

-------------------------------------------

if not fs.exists("/etc/lock.cfg") then
    su.saveFile("/etc/lock.cfg", serialization.serialize({lock = false, passwordSha256 = false, users = {}, mainuser = false, adminAllow = false}))
end
local lockCfg = serialization.unserialize(su.getFile("/etc/lock.cfg"))

-------------------------------------------

local function unlockScreen()
    if not lockCfg.lock then return end

    local oldHookState = event.superHook
    event.superHook = false

    if math.floor(computer.getDeviceInfo()[term.screen()].width) == 1 then
        term.clear()
        print("введите пароль")
        while true do
            local inputData = io.read()
            if not inputData then computer.shutdown() end
            if sha256(inputData) == lockCfg.passwordSha256 then
                term.clear()
                break
            else
                su.logTo("/free/logs/lock.log", "uncoreect password: " .. inputData)
                print("неверный пароль")
            end
        end
    else
        local mx, my = 50, 16
        if component.isAvailable("tablet") then mx, my = term.gpu().maxResolution() end

        local gui = require("guix").create()

        local main = gui.createScene(gui.selectColor(0xFFFFFF, nil, false), mx, my)
        local cx, cy = main.getCenter()

        local i = main.createInputbox(cx - (16 // 2), cy - 1, 16, 1, "enter password", function(inputData, nikname)
            if sha256(inputData) == lockCfg.passwordSha256 then
                su.logTo("/free/logs/lock.log", "password entered" .. ((nikname and (", player: " .. nikname)) or ""))
                gui.off()
            else
                su.logTo("/free/logs/lock.log", "uncoreect password: " .. inputData .. ((nikname and (", player: " .. nikname)) or ""))

                local textScene = gui.createScene(gui.selectColor(0xFF0000, nil, false), mx, my)
                local cx, cy = textScene.getCenter()
                textScene.createLabel(1, cy, 50, 1, "неверный пароль")
                local oldScene = gui.scene
                gui.select(textScene)
                os.sleep(2)
                gui.select(oldScene)
                textScene.remove()
            end
        end)
        i.viewData = false
        i.button.backColor = gui.selectColor(0xAAAAAA, nil, true)

        local autobutton = main.createButton(cx - (16 // 2), cy + 1, 16, 1, "auto", function(_, _, _, nikname)
            if su.inTable(lockCfg.users, nikname) then
                su.logTo("/free/logs/lock.log", "auto login user: " .. nikname)

                local textScene = gui.createScene(gui.selectColor(0x00FF00, nil, false), mx, my)
                local cx, cy = textScene.getCenter()
                textScene.createLabel(1, cy, 50, 1, "с возврашениям " .. nikname)
                local oldScene = gui.scene
                gui.select(textScene)
                os.sleep(2)
                --gui.select(oldScene)
                gui.off()
            else
                if not su.inTable({computer.users()}, nikname) and #({computer.users()}) ~= 0 then
                    if lockCfg.adminAllow then
                        su.logTo("/free/logs/lock.log", "auto login admin: " .. nikname)

                        local textScene = gui.createScene(gui.selectColor(0x00FF00, nil, false), mx, my)
                        local cx, cy = textScene.getCenter()
                        textScene.createLabel(1, cy, 50, 1, "разблокировано по админ доступу")
                        local oldScene = gui.scene
                        gui.select(textScene)
                        os.sleep(2)
                        --gui.select(oldScene)
                        gui.off()
                    else
                        su.logTo("/free/logs/lock.log", "err auto login admin: " .. nikname)

                        local textScene = gui.createScene(gui.selectColor(0xFF0000, nil, false), mx, my)
                        local cx, cy = textScene.getCenter()
                        textScene.createLabel(1, cy, 50, 1, "админ доступ выключен, обратитесь к владельцу пк")
                        if lockCfg.mainuser then
                            textScene.createLabel(1, cy + 2, 50, 1, "владелец (" .. lockCfg.mainuser .. ")")
                        end
                        local oldScene = gui.scene
                        gui.select(textScene)
                        os.sleep(2)
                        gui.select(oldScene)
                        textScene.remove()
                    end
                else
                    su.logTo("/free/logs/lock.log", "err auto login user: " .. nikname)

                    local textScene = gui.createScene(gui.selectColor(0xFF0000, nil, false), mx, my)
                    local cx, cy = textScene.getCenter()
                    textScene.createLabel(1, cy, 50, 1, "вас нету в таблице пользователей")
                    if lockCfg.mainuser then
                        textScene.createLabel(1, cy + 2, 50, 1, "владелец (" .. lockCfg.mainuser .. ")")
                    end
                    local oldScene = gui.scene
                    gui.select(textScene)
                    os.sleep(2)
                    gui.select(oldScene)
                    textScene.remove()
                end
            end
        end)
        autobutton.backColor = gui.selectColor(0xAAAAAA, nil, true)

        local offbutton = main.createButton(1, 1, 5, 1, "off", function(_, _, _, nikname)
            su.logTo("/free/logs/lock.log", "computer off: " .. nikname)
            computer.shutdown()
        end)
        offbutton.backColor = gui.selectColor(0xFF0000, nil, true)


        main.createTimer(0.05, function()
            i.draw()
        end)

        gui.select(main)
        gui.run()
    end

    event.superHook = oldHookState

    return true
end

while true do
    local ok, err = pcall(unlockScreen)
    if not ok then
        su.logTo("/free/logs/lockError.log", err or "unkown")
    else
        return err --err еще и возврат функции
    end
end