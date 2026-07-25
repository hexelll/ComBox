return function (_,input,alias)
    local blur = input[alias] or {}
    if blur.disable then
        return input
    end
    local strength = blur.strength or 0.5
    input.image = input.image:map(function(self,u,v)
        local x,y = self:uvToXy(u,v)
        local px = self:getPx(u,v)
        local p1 = (self:getPxXy(x-1,y) or px)
        local p2 = (self:getPxXy(x+1,y) or px)
        local p3 = (self:getPxXy(x,y-1) or px)
        local p4 = (self:getPxXy(x,y+1) or px)
        return ((1-strength)*px+strength*(p1+p2+p3+p4)/4):clamp()
    end,input.masks[blur.mask])
    return input
end