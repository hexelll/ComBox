return function(_,input,alias)
    local zoom = input[alias]
    local level = zoom.level or 1
    local x = zoom.x or 0
    local y = zoom.y or 0
    input.image = input.image:map(function(self,u,v)
        u = (u+x) / level + 0.5-0.5/level
        v = (v+y) / level + 0.5-0.5/level
        return self:getPx(u,v)
    end,input.masks[zoom.mask])
    return input
end