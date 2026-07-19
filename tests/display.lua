package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local pipeline = require("pipelines.Display")
local Color = require "Color"

local mon = peripheral.find("monitor")
mon.clear()

local sx,sy = mon.getSize()
local scx,scy = sx*0.8,sy*0.8

pipeline
:debug()
:start{
    dither={bayer=16},
    screenx=scx,
    screeny=scy,
    px=(sx-scx)/2,
    py=(sy-scy)/2,
    resize={method='mean'},
    path="images/"..arg[1],
    term=mon,
    combinator="SquarePixelCombinator"
}