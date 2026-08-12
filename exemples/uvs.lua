package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local Color = require "Color"
local Renderer = require "Renderer"
local ImageHandler = require "ImageHandler"

if not arg[1] then
    error("the first argument should be the name of a combinator, ex: FastCharCombinator")
end

local combinator = require ("combinators."..arg[1]):new()

local mon = peripheral.find("monitor")
if mon then
    mon.setTextScale(0.5)
end

local screen = Renderer:new{
    term=mon,
    combinators = { combinator }
}

local image = ImageHandler:new(
    screen.sx,
    screen.sy
):process(function(self,u,v)
    return Color(u,v):gamma2()
end)

screen:render(image):display()