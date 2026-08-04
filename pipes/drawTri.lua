local function round(x)
    return math.floor(0.4999+x)
end

local function eval(x,...)
    return type(x) == 'function' and x(...) or x
end
local function evalVec(image,u,...)
    local v = {}
    v[1] = u[1] and eval(u[1],...) or 0
    v[2] = u[2] and eval(u[2],...) or 0
    if u[3] == 'px' then
        v[1] = (u[1]-1)/(image.sx-1)
        v[2] = (u[2]-1)/(image.sy-1)
    end
    return v
end

local function line(from,to,image)
    local x0 = round(from[1]*(image.sx-1))
    local y0 = round(from[2]*(image.sy-1))
    local x1 = round(to[1]*(image.sx-1))
    local y1 = round(to[2]*(image.sy-1))
    
    local dx = x1-x0
    local dy = y1-y0
    if dx == 0 then
        return false
    end
    local a = dy/dx
    local b = y1-a*x1
    return function(x)
        return a*x+b
    end
end

local function argmin(args,k)
    local mini = 1
    local minv = args[1][k]
    for i,v in ipairs(args) do
        if v[k] < minv then
            minv = v[k]
            mini = i
        end
    end
    return mini
end

local function evalPoints(image,points,...)
    local p = {}
    points = eval(points,...)
    for i=1,#points do
        p[i] = evalVec(image,eval(points[i],...),...)
    end
    return p
end

return function(_,input,alias)
    local args = input[alias]
    local image = input.image
    local col = args.color
    local points = args.points or error('no points provided to drawTri')
    points = evalPoints(image,points,input,alias)
    local mini = argmin(points,1)

    local p = {points[mini]}
    for i=1,#points do
        if i ~= mini then
            p[#p+1] = points[i]
        end
    end

    local x = p[1][1]
    local y = p[1][2]
    image:setPx(x,y,eval(col,x-points[1][1],y-points[1][2],0,x,y,input))
    
    local switched = false
    local line1 = line(p[1],p[2],image)
    if not line1 then
        line1 = line(p[2],p[3],image)
        switched = true
    end
    local line2 = line(p[1],p[3],image)
    if not line2 then
        if switched then
            return input
        end
        line2 = line(p[2],p[3],image)
        switched = true
    end
    switched = false
    local dx = 1/(image.sx)

    local a = vector.new(points[1][1],points[1][2],0)
    local b = vector.new(points[2][1],points[2][2],0)
    local c = vector.new(points[3][1],points[3][2],0)

    local v0,v1 = b - a, c - a

    local y1,y2
    local pixels = {}
    while true do
        local X = round(x*(image.sx-1))
        y1 = line1(X)
        y2 = line2(X)
        local dy = y2-y1
        local s = dy > 0 and 1/image.sy or -1/image.sy
        
        for y=y1,y2,s do
            local u,v = x,y/(image.sy-1)
            if u >= 0 and u <= 1 and v >= 0 and v <= 1 then
                local p = vector.new(u,v,0)
                local v2 = p - a
                local d00 = v0:dot(v0)
                local d01 = v0:dot(v1)
                local d11 = v1:dot(v1)
                local d20 = v2:dot(v0)
                local d21 = v2:dot(v1)
                local denom = d00 * d11 - d01 * d01
                V = (d11 * d20 - d01 * d21) / denom
                W = (d00 * d21 - d01 * d20) / denom
                U = 1 - V - W

                U,V,W = math.min(1,math.max(0,U)),math.min(1,math.max(0,V)),math.min(1,math.max(0,W))
                pixels[#pixels+1] = {u,v,eval(col,U,V,W,u,v,input,alias)}
            end
        end

        x=x+dx

        if x >= p[2][1] and x >= p[3][1] then
            for _,p in pairs(pixels) do
                image:setPx(p[1],p[2],p[3])
            end
            return input
        end
        if not switched and x >= p[2][1] then
            line1 = line(p[2],p[3],image)
            switched = true
        end
        if not switched and x >= p[3][1] then
            line2 = line(p[3],p[2],image)
            switched = true
        end
        if not line2 or not line1 then
            for _,p in pairs(pixels) do
                image:setPx(p[1],p[2],p[3])
            end
            return input
        end
    end
end