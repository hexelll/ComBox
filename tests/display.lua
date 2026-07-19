package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local pipeline = require("pipelines.Display")
local Color = require "Color"

pipeline
:blur()
:sharpen()
:debug()
--:pipe("sharpen")
:start{
    resize={method='naive'},
    path="images/"..arg[1],
    term=peripheral.find("monitor"),
    combinator="SquarePixelCombinator"
}