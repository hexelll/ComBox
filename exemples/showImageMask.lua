package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local Color = require "Color"
local Renderer = require "Renderer"
local MediaParser = require "MediaParser"

local mainCombinator = require ("combinators."..arg[2]):new()
local edgeCombinator = require ("combinators."..arg[3]):new()

local imagePath = arg[1]

local mon = peripheral.find("monitor")
if mon then
    mon.setTextScale(0.5)
end

local screen = Renderer:new{
    term=mon,
    combinators={ mainCombinator, edgeCombinator}
}

local image = MediaParser:open(imagePath)
if arg[4] == "nearest" then -- faster but pretty ugly
    image:resize(screen.sx,screen.sy)
elseif arg[4] == "mean" then -- slower but much nicer
    image:resize(200,200) -- we resize to 200 by 200 so it doesn't take too long to compute
        :resizeMean(
            screen.sx,
            math.floor(screen.sy*3/2+0.5) -- this is necessary for SquarePixelCombinator, the image needs to be at least 3/2 times taller than the monitor
        )
else
    error("the second argument should be \"nearest\" or \"mean\"")
end

local function makeMask(image)
    return image:map(function(self,u,v)
        local vec = {0,0}
        local color = self:getPx(u,v)
        for x=-1,1 do
            for y=-1,1 do
                local ku,kv = x/(self.sx-1),y/(self.sy-1)
                local px = self:getPx(u+ku,v+kv)
                px = px and px or Color:new()
                local d = color:distance(px)
                vec[1] = vec[1] + x*d
                vec[2] = vec[2] + y*d
            end
        end
        local l = math.sqrt(vec[1]*vec[1]+vec[2]*vec[2])
        if l > 0.1 then
            return edgeCombinator
        end
   
        return mainCombinator
    end,screen.sx,screen.sy)
end

screen.mask = makeMask(image)
screen:render(image):display()