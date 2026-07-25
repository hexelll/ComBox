package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory
local import = require 'import'

import:setDir('../')

local Color = import "Color.lua"
local Renderer = import "Renderer.lua"
local ImageHandler = import "ImageHandler.lua"

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

local function palette( t )
    local a = Color(0.5, 0.5, 0.5);
    local b = Color(0.5, 0.5, 0.5);
    local c = Color(1.0, 1.0, 1.0);
    local d = Color(0.263,0.416,0.557);
    local out = Color()
    
    out[1] = a[1]+b[1]*math.cos(6.28318*(c[1]*t+d[1]))
    out[2] = a[2]+b[2]*math.cos(6.28318*(c[2]*t+d[2]))
    out[3] = a[3]+b[3]*math.cos(6.28318*(c[3]*t+d[3]))
    
    return out
end

local function fract(x)
    return x-math.floor(x)
end

local T = 0
while true do
    local image = ImageHandler:new(
        screen.sx,
        screen.sy
        --math.floor(screen.sy*3/2+0.5)
    ):process(function(self,u,v)
        u=(u*2-1)*self.sx/self.sy
        local u0 = u
        v=v*2-1
        local v0 = v
        local c = Color();
        local l0 = length(u0,v0)
        local k = math.exp(-l0)
        for i=0,2 do
            u=fract(u*1.5)-0.5
            v=fract(v*1.5)-0.5
            local d = length(u,v)*k
            local col = palette(l0+i*4+T*4)
            d = math.abs(math.sin(d*8+T)/8)
            d = (0.01/d)^1.2
            c = c+col*d
        end
        if(c[1] >= 0 and c[2] >= 0 and c[3] >= 0) then
            return c
        end
        return Color()
    end)

    screen:render(image):display()
    sleep()
    T=os.clock()*0.8
end