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

local function length(x,y)
    return math.sqrt(x*x+y*y)
end

local T = 0
while true do
    local image = ImageHandler:new(
        screen.sx,
        math.floor(0.5+screen.sy*3/2)
    ):process(function(self,u,v)
        local c = Color();
        local l
        local t = T
        local z = t
        for i=1,3 do
            local pu = u - 0.5
            local pv = v - 0.5
            pu=pu * self.sx/self.sy
            z=z+0.07;
            l=length(pu,pv)
            local k = (math.sin(t)+1)*math.abs(math.sin(l*9-2*z))
            u = u + k*pu/l
            v = v + k*pv/l
            c[i]=0.01/(math.max(length((u%1)-0.5,(v%1)-0.5),0.0001))
        end
        c[1] = 2*c[1]/l
        c[2] = 2*c[2]/l
        c[3] = 2*c[3]/l
        if(c[1] >= 0 and c[2] >= 0 and c[3] >= 0) then
            return c:gamma2()
        end
        return Color()
    end)

    screen:render(image):display()
    sleep()
    T=T+0.05
end