local fp = fs.open("/.combox_secrets","r")
local path = fp.readAll()
fp.close()

package.path = package.path .. ";"..path.."?.lua" -- this is used so we can require from another directory

local Color = require "Color"

return function(_,input,alias)
    local maskEdge = input[alias] or {}
    local edgeCoeff = maskEdge.edgeCoeff or 0.1
    input.screen.mask = input.image:map(function(self,u,v)
        local vec = {0,0}
        local color = self:getPx(u,v)
        for x=-1,1 do
            for y=-1,1 do
                local ku,kv = x/(self.sx-1),y/(self.sy-1)
                local px = self:getPx(u+ku,v+kv)
                px = px and px or color
                local d = color:distance(px)
                vec[1] = vec[1] + x*d
                vec[2] = vec[2] + y*d
            end
        end
        local l = math.sqrt(vec[1]*vec[1]+vec[2]*vec[2])
        if l > edgeCoeff then
            return input.screen.combinators[2]
        end
        return input.screen.combinators[1]
    end,input.sx,input.sy)
    return input
end