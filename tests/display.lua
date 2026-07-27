package.path = package.path..';../?.lua'

local import = require 'import'

import
    :setDownloadDir("/vendor/combox")
    :setDir("https://raw.githubusercontent.com/hexelll/ComBox/refs/heads/dev/")
    --:setDir('../')
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

local image = MediaParser:open("images/"..arg[1]):resize(200,200):resizeMean(scx,scy*3/2)

local biden = MediaParser:open("images/biden.qoi"):resize(200,200):resizeMean(scx,scy*3/2)

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
    :sharpen{strength=2}
    :image{
        image=function(self,input)
            return biden:resize(input.sx,input.sy):value()
        end,
        from=function(s,img)
            return {
                0.5+math.cos(os.clock())/4-0.5/2,
                0.5+math.sin(os.clock())/4-0.8/2
            }
        end,
        to=function(s,img,from)
            return {
                from[1]+0.5,
                from[2]+0.8
            }
        end
    }
    -- :sharpen()
    -- :crt()
    -- :chromAberration{strength=1}
    -- :after('render',function(_,input)
    --     input.screen.term.setBackgroundColor(2^(Color():findClosest(input.screen.palette)-1))
    --     input.screen.term.clear()
    --     return input
    -- end)

while true do
    pipeline:start{
        sx=scx,
        sy=scy,
        generatePalette={method='kmeans',size=16},
        resize={method='mean'},
        dither={spread=0.1,bayer=16},
        image=image,
        term=mon,
        combinators={
            --'FastCharCombinator',
            "SquarePixelCombinator",
            --import("combinators/ASCIICombinator.lua"):new{chars={'\143'}},
            "FlowCombinator"
        }
    }
    sleep()
end