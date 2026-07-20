package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local dir = shell.dir()

shell.setDir(fs.getDir(shell.getRunningProgram()))

local import = require "import"

local pipeline = import "../pipelines/Display.lua"

local Color = import "../Color.lua"

local mon = peripheral.find("monitor")
mon.clear()

local sx,sy = mon.getSize()
local scx,scy = sx*1,sy*0.7

pipeline
:debug()
:start{
    resizeSharpen={strength=2},
    dither={spread=0.1,bayer=16},
    screenx=scx,
    screeny=scy,
    px=(sx-scx)/2,
    py=(sy-scy)/2,
    resize={method='mean'},
    path="../images/"..arg[1],
    term=mon,
    combinator="SquarePixelCombinator"
}

shell.setDir(dir)