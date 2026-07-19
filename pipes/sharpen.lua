package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local Color = require "Color"

return function(_,input)
    input.sharpen = input.sharpen or {}
    local sharpness = input.sharpen.strength or 2
    input.image = input.image:map(function(self,u,v)
        local x,y = self:uvToXy(u,v)
        local px = self:getPx(u,v)
        local p1 = (self:getPxXy(x-1,y) or px)
        local p2 = (self:getPxXy(x+1,y) or px)
        local p3 = (self:getPxXy(x,y-1) or px)
        local p4 = (self:getPxXy(x,y+1) or px)
        return (px + (px-(p1+p2+p3+p4)/4) * sharpness):clamp()
    end)
    return input
end