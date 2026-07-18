package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local pipeline = require("pipelines.Display")
local Color = require "Color"

pipeline
:before("render","dither")
:process(function(self,u,v) return self:getPx(u,v):gray() end)
:start{
    generatePalette={method='kmeans',size=16},
    dither={spread=0.1,bayer=16},
    path="images/"..arg[1],
    term=peripheral.find("monitor"),
    combinator="SquarePixelCombinator",
}