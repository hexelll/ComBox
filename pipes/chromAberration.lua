local Color = import '../Color.lua'

return function(_,input,alias)
    local args = input[alias]
    local strength = args.strength or 1
    input.image = input.image:map(function(self,u,v)
        local px = self:getPx(u,v)
        local ru = u-strength/input.sx
        local gu = u
        local bu = u+strength/input.sx
        local rv = v
        local gv = v
        local bv = v
        local pr,pg,pb = self:getPx(ru,rv) or px,self:getPx(gu,gv) or px,self:getPx(bu,bv) or px
        return Color(pr[1],pg[2],pb[3])
    end,input.masks[args.mask])

    return input
end