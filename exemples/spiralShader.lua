package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local Color = require "Color"
local ImageHandler = require "ImageHandler"
local Renderer = require "Renderer"

local FastCharCombinator = require("combinators.FastCharCombinator"):new()

local mon = peripheral.find("monitor")
if mon then
    mon.setTextScale(0.5)
end

local screen = Renderer:new{
    term = mon,
    combinators= {FastCharCombinator}
}

local k = 0.5
local n = 5

local spiral = function(self,u,v)
    local ratio = self.sx/self.sy
    local x = (u-0.5)*ratio*k*2
    local y = (v-0.5)*k*2
    local s = math.sqrt(x^2+y^2)
    local sx = x/s
    local sy = y/s
    local r = (math.abs(x)^k+math.abs(y)^k)^(1/k)
    local a = math.atan2(y,x)
    local d = math.abs((r-(a+(os.clock())%(math.pi*2)))%(math.pi/(n/2)))/(r+0.001)
    d = math.min(1,math.max(1-math.abs(d * (r^2)/k),0))
    return Color(d,d,d)
end

local image = ImageHandler:new(screen.sx,screen.sy):process(spiral)
while true do
    image:process(spiral)
    screen:render(image):display()
    sleep()
end