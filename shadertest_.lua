local Renderer = require "Renderer"
local ImageHandler = require "ImageHandler"
local Color = require "Color"
local MediaParser = require "MediaParser"

local CharCombinator = require "combinators.FastCharCombinator":new()
local SquarePixelCombinator = require "combinators.SquarePixelCombinator":new()

local FlowCombinator = require "combinators.FlowCombinator":new()

local MathCharCombinator = require "combinators.MathCharCombinator":new()

local PixelCombinator = require "combinators.PixelBoxCombinator":new()

local ASCIICombinator = require 'combinators.ASCIICombinator':new()

local mon = peripheral.find("monitor")

mon.setTextScale(0.5)

local screen = Renderer:new{
    term=mon,
    combinators={FlowCombinator,ASCIICombinator,CharCombinator,SquarePixelCombinator,MathCharCombinator}
}

local round = function(x)
    return math.floor(x+0.5)
end

local function makeMask(image)
    return image:map(function(self,u,v)
        local vec = {0,0}
        local color = self:getPx(u,v)
        for x=-1,1 do
            for y=-1,1 do
                ku,kv = x/(self.sx-1),y/(self.sy-1)
                local px = self:getPx(u+ku,v+kv)
                px = px and px or Color:new()
                local d = color:distance(px)
                vec[1] = vec[1] + x*d
                vec[2] = vec[2] + y*d
            end
        end
        local l = math.sqrt(vec[1]*vec[1]+vec[2]*vec[2])
        if l > 0.1 then
            return SquarePixelCombinator
        end
   
        return CharCombinator
    end,screen.sx,screen.sy)
end

local n = 3

local k = 1
local T = os.clock()
local luc = MediaParser:open("images/"..arg[1]):resizeMean(screen.sx,round(screen.sy*3/2))
local spiral = function(self,u,v)
    local ratio = self.sx/self.sy
    local x = (u-0.5)*ratio*k*2
    local y = (v-0.5)*k*2
    local s = math.sqrt(x^2+y^2)
    local sx = x/s
    local sy = y/s
    local r = (math.abs(x)^k+math.abs(y)^k)^(1/k)
    local a = math.atan2(y,x)
    local d = math.abs((r-(a+(T)%(math.pi*2)))%(math.pi/(n/2)))/(r+0.001)
    d = math.min(1,math.max(1-math.abs(d * (r^2)/k),0))
    return Color(d,d,d)
end

local waves = {}

local wave = function(self,u,v)
    local ratio = self.sx/self.sy
    local dx = 0
    local dy = 0
    local k = 1
    for _,val in pairs(waves) do
        local mx = val[1]
        local my = val[2]
        local tstart = val[3]
        local x = (u-mx)*ratio
        local y = (v-my)

        local s = math.sqrt(x*x+y*y)

        sx = x/s
        sy = y/s

        local d = (s-(os.clock()-tstart))*10
        d = math.max((1-math.abs(d)),0)*0.05
        dx = dx+sx*d
        dy = dy+sy*d

    end
    local c = luc:getPx(u-dx,v-dy) or Color()
    return c
end


local image = ImageHandler:new(screen.sx,round(screen.sy*3/2)):process(wave)

local palettergb = {
    {20, 12, 28},
    {68, 36, 52},
    {48, 52, 109},
    {78, 74, 78},
    {133, 76, 48},
    {52, 101, 36},
    {208, 70, 72},
    {117, 113, 97},
    {89, 125, 206},
    {210, 125, 44},
    {133, 149, 161},
    {109, 170, 44},
    {210, 170, 153},
    {109, 194, 202},
    {218, 212, 94},
    {222, 238, 214}
}

local palette = image:findPalette()
for i=1,#palettergb do
    local c = palettergb[i]
    --palette[i] = Color(c[1]/255,c[2]/255,c[3]/255)
end
local i = 0
parallel.waitForAny(
    function()
while true do
    T = os.clock()
    image:process(wave)--:linearize()
    screen.mask = makeMask(image,palette)
    screen
        :render(image,palette)
        .display()
    sleep()
end
end,
function()
    while true do
        local e,_,x,y = os.pullEvent("monitor_touch")
        mx,my = x/screen.sx,y/screen.sy
        tstart = os.clock()
        waves[i] = {mx,my,tstart}
        i=(i+1)%20
    end
end
)