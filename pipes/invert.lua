return function(_,input)
    input.image:process(function(self,u,v)
        return self:getPx(u,v):invert()
    end)
    return input
end