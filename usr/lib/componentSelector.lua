local component = require("component")

local componentSelector = {}

------------------------------------------------------

componentSelector.getAddress = function(name, message)
    local addresses = {}
    for address in component.list(name) do
        addresses[#addresses + 1] = address
    end

    if message then
        message = "для "..message
    else
        message = ""
    end

    if #addresses == 0 then
        print("отсутствует компонент "..name.." к которому программа хочет получить доступ "..message..", это может стать причиной ошибок или некоректной работы программы")
        return
    elseif #addresses == 1 then
        return addresses[1]
    end

    print("выбрите компонент "..name.." "..message..":")
    local counter = 0
    for i = 1, #addresses do
        counter = counter + 1
        print(counter..": "..addresses[i]..".")
    end
    while true do
        local number = io.read()
        if number ~= nil and type(number) == "string" then
            number = tonumber(number)
            if number > 0 and number <= #addresses then
                return addresses[number]
            end
        end
        print("ошибка ввода")
    end
end

componentSelector.getComponent = function(name, message)
    local address = componentSelector.getAddress(name, message)
    if not address then
        return
    end
    return component.proxy(address)
end

------------------------------------------------------

return componentSelector