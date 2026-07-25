return function(_,input,alias)
    local invert = input[alias] or {}
    if invert.disable then
        return input
    end
    input.image:process(function(self,u,v)
        return self:getPx(u,v):invert()
    end,input.masks[invert.mask])
    return input
end