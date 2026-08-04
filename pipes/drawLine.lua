local Color = import '../Color.lua'

local function round(x)
    return math.floor(0.4999+x)
end

local function eval(x,...)
    return type(x) == 'function' and x(...) or x
end
local function evalVec(u,...)
    local v = {}
    v[1] = u[1] and eval(u[1],...) or 0
    v[2] = u[2] and eval(u[2],...) or 0
    if u[3] == 'px' then
        v[1] = (u[1]-1)/(self.sx-1)
        v[2] = (u[2]-1)/(self.sy-1)
    end
    return v
end

return function(_,input,alias)
    local args = input[alias]
    local image = input.image
    local mask = input.masks[args.mask]
    local col = args.color or Color()
    local from = evalVec(args.from and eval(args.from,self,image) or {0,0})
    local to = evalVec(args.to and eval(args.to,self,image,from) or {image.sx,image.sy,'px'})

    local x0 = round(from[1]*(image.sx-1))
    local y0 = round(from[2]*(image.sy-1))
    local x1 = round(to[1]*(image.sx-1))
    local y1 = round(to[2]*(image.sy-1))
    
    local dx = math.abs(x1 - x0)
    local sx = x0 < x1 and 1 or -1
    local dy = -math.abs(y1 - y0)
    local sy = y0 < y1 and 1 or -1
    local err = dx + dy
    
    while true do
        local u,v = x0/(image.sx-1),y0/((image.sy-1))
        local color = type(col) == "function" and col(from[1]+u,from[2]+v,u,v) or col
        image:setPx(u,v,color)
        local e2 = 2 * err
        if e2 >= dy then
            if x0 == x1 then
                break
            end
            err = err + dy
            x0 = x0 + sx
        end
        if e2 <= dx then
            if y0 == y1 then
                break
            end
            err = err + dx
            y0 = y0 + sy
        end
    end
    return input
end