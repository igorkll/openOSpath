os.execute("setresolution")
os.execute("depth set")
os.execute("resetPalette")

local term = require("term")
if term.isAvailable() then
    local gpu = term.gpu()
    gpu.setBackground(0)
    gpu.setForeground(0xFFFFFF)
    term.clear()
end