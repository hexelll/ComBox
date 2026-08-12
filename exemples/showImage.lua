package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local Renderer = require "Renderer"
local MediaParser = require "MediaParser"

local combinator = require ("combinators."..arg[3]):new()

local imagePath = arg[1]

local mon = peripheral.find("monitor")
if mon then
    mon.setTextScale(0.5)
end

local screen = Renderer:new{
    term=mon,
    combinators={ combinator }
}

local image = MediaParser:open(imagePath)
if arg[2] == "nearest" then -- faster but pretty ugly
    image:resize(screen.sx,screen.sy)
elseif arg[2] == "mean" then -- slower but much nicer
    image:resize(200,200) -- we resize to 200 by 200 so it doesn't take too long to compute
         :resizeMean(screen.sx,screen.sy)
else
    error("the second argument should be \"nearest\" or \"mean\"")
end

screen:render(image):display()