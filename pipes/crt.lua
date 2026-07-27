return function(_,input,alias)
    local args = input[alias]
    local base = args.base or 0.8
    local strength = args.strength or 0.4
    local rate = args.rate or 4
    local vrate = args.vrate or 0.03
    local baseStrength = args.baseStrength or 0.4
    local sy = input.screen.sy
    if input.screen.combinators[1].ratio then
        sy = math.floor(0.5+sy*input.screen.combinators[1].ratio.y)
    end
    input.image:process(function(self,u,v)
        return (self:getPx(u,v)*(base+strength*(math.floor(0.4999+v*(sy-1))%2)*(baseStrength+math.abs(math.sin(v*vrate*sy+rate*os.clock()))))):clamp()
    end)
    return input
end