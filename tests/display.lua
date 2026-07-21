package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local dir = shell.dir()

shell.setDir(fs.getDir(shell.getRunningProgram()))

local import = require "import"

local pipeline = import "../pipelines/Display.lua"
local MediaParser = import "../MediaParser.lua"
local Color = import "../Color.lua"

local mon = peripheral.find("monitor")
mon.clear()

local sx,sy = mon.getSize()
local scx,scy = sx*1,sy*1

local image = MediaParser:open("../images/"..arg[1])

while true do
    pipeline
    :start{
        screenx=scx,
        screeny=scy,
        sx=1+math.floor((scx-1)*(1+math.sin(os.clock()))/2),
        sy=scy,
        px=(sx-scx)/2,
        py=(sy-scy)/2,
        resize={method='naive'},
        image=image,
        term=mon,
        combinator="SquarePixelCombinator"
    }
    sleep()
end
shell.setDir(dir)