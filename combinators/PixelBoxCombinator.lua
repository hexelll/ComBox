local pixelbox = require "pixelbox_lite"

local Color = require("Color")

local combinator = {name="PixelBoxCombinator"}

local hexTable = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"}

function combinator:new()
    local o = {}
    setmetatable(o,{
        __index=function(_,k)
            return self[k]
        end
    })
    return o
end

function round(x)
    return math.floor(x+0.5)
end

function combinator:onPaletteChange()

end

function combinator:onImageChange(image,palette,renderer)
    local box = pixelbox.new(
        renderer.term,
        colors.black
    )
    for y=0,renderer.sy*3-1 do
        for x=0,renderer.sx*2-1 do
            local v,u = y/(renderer.sy*3-1),x/(renderer.sx*2-1)
            box:set_pixel(x+1,y+1,2^(image:getPx(u,v):findClosest(palette)-1))
        end
    end
    self.lines = box:render()
end

function combinator:findCombination(u,v,image,palette,renderer)
    local x,y = 1+round(u*(renderer.sx-1)),1+round(v*(renderer.sy-1))
    if not self.lines then
        return {"?","0","0"}
    end
    return {self.lines[y][1][x],self.lines[y][2][x],self.lines[y][3][x]}
end
return combinator