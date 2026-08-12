package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local Color = require "Color"
local Renderer = require "Renderer"
local ImageHandler = require "ImageHandler"
local MediaParser = require "MediaParser"

local mon = peripheral.find("monitor")
if mon then
    mon.setTextScale(0.5)
end

local combinator = require("combinators.FastCharCombinator"):new()

local screen = Renderer:new{
    term=mon,
    combinators={combinator}
}

local gar = MediaParser
    :open("images/gar.qoi")
    :resizeMean(screen.sx,math.floor(0.5+screen.sy*3/2))

function makeImage(t)
    local image = gar
        :map(function(self,u,v)
            local px = self:getPx(u,v)
            u=u-0.5
            v=v-0.5
            local k = 1-math.max(0,math.min(1,2*(u*u+v*v)*(1+math.sin(t*20))/2))
            return px*k
        end)
    return screen:render(
        image
    )
end

local images = {}

local refreshRate = 1/12
local time = 10 -- seconds

local start = os.clock()

local i = 1
local skippedTotal = 0
while i < time/refreshRate do
    local T = os.clock()
    local t = refreshRate*(i-1)/time
    images[i] = images[i] or makeImage(t)
    images[i].display()
    local dt = os.clock()-T
    while dt < refreshRate do
        if dt < refreshRate/2 and #images+1 - i < time/refreshRate then
            t=(#images+1)*refreshRate/time
            images[#images+1] = makeImage(t)
        end
        dt = os.clock()-T
    end
    local skipped = -1
    while dt > refreshRate do
        i = i + 1
        skipped = skipped + 1
        dt = dt - refreshRate
    end
    skippedTotal = skippedTotal + skipped
    sleep(0)
end

local endT = os.clock()

print("elapsed time: "..endT-start)
print("skipped "..skippedTotal)
print("skipped seconds "..skippedTotal*refreshRate)