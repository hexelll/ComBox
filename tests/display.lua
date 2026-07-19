package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local pipeline = require("pipelines.Display")
local Color = require "Color"

local paletteSize = 16

pipeline
:debug()
--:remove("dither")
:pipe("blur")
--:pipe("maskEdge")
--:pipe("image")
--:process(function(self,u,v) return Color(u,v) end)
--:process(function(self,u,v) return self:getPx(u,v):gray() end)
:start{
    generatePalette={method='kmeans',size=paletteSize},
    dither={spread=0.1,bayer=16},
    resize={method='naive'},
    path="images/"..arg[1],
    term=peripheral.find("monitor"),
    combinators={
        --"FastCharCombinator",
        "SquarePixelCombinator"
    },
}