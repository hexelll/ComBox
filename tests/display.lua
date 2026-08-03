package.path = package.path..';../?.lua'

local import = require 'import'

import
    --:setDownloadDir("/vendor/combox")
    --:setDir("https://raw.githubusercontent.com/hexelll/ComBox/refs/heads/dev/")
    :setDir('../')
print("loading Combox")
local pipeline = import "pipelines/Display.lua"
local MediaParser = import "MediaParser.lua"
local Color = import "Color.lua"
--local Texture = import "Texture.lua"
local ImageHandler = import "ImageHandler.lua"
print("finished loading")

local mon = peripheral.find("monitor")
mon.clear()

local sx,sy = mon.getSize()
local scx,scy = sx*1,sy*1

local A = MediaParser:open("images/"..arg[1]):resize(200,200):resizeMean(scx,scy*3/2)
local B = MediaParser:open("images/"..arg[2]):resize(200,200):resizeMean(scx,scy*3/2)

-- local biden = MediaParser:open("images/biden.qoi"):resize(200,200):resizeMean(scx,scy*3/2)

local function randPoint()
    return {math.random(),math.random()}
end

pipeline
    -- :image{
    --     at={0.5,0},
    --     sx=4,
    --     sy=10,
    --     create=function(_,input,alias)
    --         Texture(input.image)
    --             :drawLine{
    --                 from={0,0},
    --                 to={10,10,'px'},
    --                 -- u,v relatifs à l'élément
    --                 color=function(self,u,v,t) -- self = {from,to,image,...}
    --                     return Color(t,t,t)
    --                 end
    --             }
    --             :drawRectangle{
    --                 from={0,0},
    --                 to={0.5,0.5},
    --                 -- u,v relatifs à l'élément
    --                 color=function(self,u,v) -- self = {from,to,image,...}
    --                     return Color(u,v)
    --                 end
    --             }
    --             :drawText{
    --                 at={0.5,0.5},
    --                 -- u,v relatifs à l'élément
    --                 color=function(self,u,v,c) -- self = {at,image,...}
    --                     return Color(u,v)
    --                 end
    --             }
    --     end
    -- }
    -- :sharpen{strength=2}
    -- :crt()
    -- :chromAberration()
    -- :image{
    --     image=function(self,input)
    --         return biden:resize(input.sx,input.sy):value()
    --     end,
    --     from=function(s,img)
    --         return {
    --             0.5+math.cos(os.clock())/4-0.5/2,
    --             0.5+math.sin(os.clock())/4-0.8/2
    --         }
    --     end,
    --     to=function(s,img,from)
    --         return {
    --             from[1]+0.5,
    --             from[2]+0.8
    --         }
    --     end
    -- }
    :drawQuad('quad')
    --:dither()
    -- :sharpen()
    -- :crt()
    -- :chromAberration{strength=1}
    -- :after('render',function(_,input)
    --     input.screen.term.setBackgroundColor(2^(Color():findClosest(input.screen.palette)-1))
    --     input.screen.term.clear()
    --     return input
    -- end)

local s = 0.9
local paletteRaw = {
  {
    0.85803921568627,
    0.88705882352941,
    0.88705882352941,
  },
  {
    0.75599128540305,
    0.75686274509804,
    0.74989106753813,
  },
  {
    0.33267973856209,
    0.26372549019608,
    0.2578431372549,
  },
  {
    0.61084198385236,
    0.55478662053057,
    0.50611303344867,
  },
  {
    0.42875816993464,
    0.42679738562092,
    0.45032679738562,
  },
  {
    0.18529411764706,
    0.18627450980392,
    0.20588235294118,
  },
  {
    0.33267973856209,
    0.32156862745098,
    0.35555555555556,
  },
  {
    0.67058823529412,
    0.64385026737968,
    0.61711229946524,
  },
  {
    0.40896358543417,
    0.3546218487395,
    0.32436974789916,
  },
  {
    0,
    0,
    0,
  },
  {
    0.54781297134238,
    0.47088989441931,
    0.41508295625943,
  },
  {
    0.50326797385621,
    0.35947712418301,
    0.32679738562092,
  },
  {
    0.46823529411765,
    0.42588235294118,
    0.36078431372549,
  },
  {
    0.34117647058824,
    0.65098039215686,
    0.30588235294118,
  },
  {
    0.8,
    0.29803921568627,
    0.29803921568627,
  },
  {
    0.066666666666667,
    0.066666666666667,
    0.066666666666667,
  },
} 

local palette = {}

for i,c in pairs(paletteRaw) do
    palette[i] = Color(c[1],c[2],c[3])
end

while true do
    local k = (1+math.sin(os.clock()))/2
    pipeline:start{
        sx=scx,
        sy=scy,
        generatePalette={method='kmeans',size=16},
        resize={method='mean'},
        --palette=palette,
        dither={spread=0.1,bayer=16},
        image=ImageHandler:new(sx,sy*3/2,Color()):process(function()return Color()end),
        term=mon,
        combinators={
            'FastCharCombinator',
            --"SquarePixelCombinator",
            --import("combinators/ASCIICombinator.lua"):new{chars={'\143'}},
            "FlowCombinator"
        },
        quad={
            points={
                {(1-s)/2+s*k,(1-s)/2},
                {(1-s)/2+s*(1-k),(1-s)/2},
                {(1-s)/2+s*k,s+(1-s)/2},
                {(1-s)/2+s*(1-k),s+(1-s)/2},
            },
            color=function(u,v)
                return (A:getPx(u,v)):mix(B:getPx(u,v),k)
            end
        },
    }
    sleep()
end