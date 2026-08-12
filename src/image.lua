--[[

    Used to represent Images, with many utils.
    Pixel data is a in a big array of Color objects.
    Uses UV coordinates as numbers in the [0,1] range

    Image: {
        sx: number,
        sy: number,
        data: [Color],
        uniqueColors: [Color], // initialised as {} by Image:new()
        debug: bool
    }

]]

if not import then error("use import to use this file not require") end

local Color = import "./color.lua"

local Image = {type='image'}


local function round(x)
    return math.floor(x+0.4999)
end

local function clamp(x)
    return math.min(math.max(x,0),1)
end

local function uvToXy(sx,sy,u,v)
    return math.max(1,1+round(u*(sx-1))) , math.max(1,1+round(v*(sy-1)))
end

local function xyToIndex(sx,x,y)
    return math.max(1,(round(y)-1)*sx + round(x),1)
end

-- internal util to calculate indexes in data
local function uvToIndex(sx,sy,u,v)
    local x,y = uvToXy(sx,sy,u,v)
    return xyToIndex(sx,x,y)
end

function Image:uvToXy(u,v)
    return uvToXy(self.sx,self.sy,u,v)
end

--[[

	Creates new instance of Image.

	new(
        self:  Image
		sx:    number,        // x size
        sy:    number,        // y size
        data:  ?[Color],      // Array of pixel Colors, 
                              // if nil : filled with transparent Black ( Color:new(0,0,0,0) )
	): Image
    
]]
function Image:new(sx,sy,default,data)
    local sx,sy = math.max(round(sx),0),math.max(round(sy),0)
    default = default or Color()

    local o = { sx=sx, sy=sy, colors={} }

    setmetatable(o,{
        __index=function(_,k)
            return self[k]
        end
    })

    if not data then
        data = {}
        local isColor = type(default) == 'table' and default.type == 'color'
        if isColor then
            local h = default:toHash(255)
            o.colors[h] = {color=default}
        end
        for i=1,sx*sy do
            if isColor then
                o.colors[h][#o.colors[h]+1] = i
            end
            data[i] = default
        end
    else
        for i,color in pairs(data) do
            local h = color:toHash(255)
            o.colors[h] = o.colors[h] or {color=color}
            o.colors[h][#o.colors[h]+1] = i
        end
    end
    
    o.data = data

    return o
end

--[[

	Same as copy but doesn't keep the original's Color objects.
    All Colors in the image will be truly duplicated, 
    not just referenced.

	duplicate(
        self: Image
    ) -> Image

]]
function Image:duplicate()
    local newData = {}
    local colors = {}
    for i=1,self.sx*self.sy do
        local color = self.data[i] and (type(self.data[i]) == 'table' and self.data[i].duplicate and self.data[i]:duplicate() or self.data[i]) or Color()
        newData[i] = color
    end

    local img = Image:new(self.sx,self.sy,nil,newData)
    return img
end

--[[

    Resizes the image using nearest-neighbor sampling.
    Fast and preserves hard edges, but may appear jagged when scaled.

	resize(
        self: Image,
        newSx: number, 
        newSy: number   
    ) -> Image

]]
function Image:resize(newSx, newSy)
    local newData = {}
    newSx = round(newSx)
    newSy = round(newSy)
    if newSx == self.sx and newSy == self.sy then
        return self
    end
    for i=0,newSx-1 do
        for j=0,newSy-1 do
            local u,v = i/(newSx-1),j/(newSy-1)
            local index,color = uvToIndex(newSx,newSy,u,v),self:getPx(u,v)
            newData[index] = color
        end
    end
    self.data = newData
    self.sx = newSx
    self.sy = newSy
    return self
end

--[[

	Resizes the image while keeping more detail then Image.resize but is much slower.
    Each pixel in the resized image is the average Color of a region of pixels from the original image.
    This is smoother than resize() but also slower and less crisp.

	resizeMean(
        self: Image,
        newSx: number, 
        newSy: number   
    ) -> Image

]]
function Image:resizeMean(newSx,newSy) -- TODO: switch to convolution
    newSx,newSy = round(newSx),round(newSy)
    local newData = {}
    if newSx > self.sx or newSy > self.sy then
        return self:resize(newSx,newSy)
    end
    local dx = round(self.sx/newSx)+1
    local dy = round(self.sy/newSy)+1
    local t = os.clock()
    for i=0,self.sx-1 do
        for j=0,self.sy-1 do
            local cs = Color()
            cs[4] = 0
            local k = 0
            for di=-dx/2,dx/2 do
                for dj=-dy/2,dy/2 do
                    local u,v = (i+di)/(self.sx-1),(j+dj)/(self.sy-1)
                    if u >= 0 and u <= 1 and v >= 0 and v <= 1 then
                        local px = self:getPx(u,v)
                        if px then
                            cs[1] = cs[1] + px[1]
                            cs[2] = cs[2] + px[2]
                            cs[3] = cs[3] + px[3]
                            cs[4] = cs[4] + px[4]
                            k=k+1
                        end
                    end
                end
            end
            cs[1] = k > 0 and cs[1]/k or 0
            cs[2] = k > 0 and cs[2]/k or 0
            cs[3] = k > 0 and cs[3]/k or 0
            cs[4] = k > 0 and cs[4]/k or 0
            local u,v = (i)/(self.sx-1),(j)/(self.sy-1)
            newData[uvToIndex(newSx,newSy,u,v)] = cs
            if os.clock()-t > 5 then
                t = os.clock()
                sleep()
            end
        end
    end
    self.data = newData
    self.sx = newSx
    self.sy = newSy
    return self
end

--[[

	Returns the Color at a specific point (u,v) of the image.

	getPx(
        self: Image,
        u: number, 
        v: number   
    ) -> Color

]]
function Image:getPx(u,v)
    if u < 0 or u > 1 or v < 0 or v > 1 then
        return
    end
    local index = uvToIndex(self.sx,self.sy,u,v)
    return self.data[index]
end

function Image:getPxXy(x,y)
    local index = xyToIndex(self.sx,x,y)
    return self.data[index]
end

function Image:registerColor(color,index)
    if type(color) == 'table' and color.type == 'color' then
        local currentColor = self.data[index]
        if currentColor then
            local indices = self.colors[currentColor:toHash(255)]
            if indices and #indices > 0 then
                local i = 1
                for k,v in pairs(indices) do
                    if v == index then
                        i = k
                        break
                    end
                end
                indices:remove(i)
            end
        end
        local h = color:toHash(255)
        indices = self.colors[h] or {color=color}
        indices[#indices+1] = index
    end
end

--[[

	Sets the Color at a specific point (u,v) of the image.

	setPx(
        self: Image,
        u: number, 
        v: number,
        color: Color // new color for the point
    ) -> Image

]]
function Image:setPx(u,v,color)
    u,v = round(u*self.sx)/self.sx,round(v*self.sy)/self.sy
    if u < 0 or u > 1 or v < 0 or v > 1 then
        return self
    end
    local index = uvToIndex(self.sx,self.sy,u,v)
    self:registerColor(color,index)
    self.data[index] = color
    self.modified = true
    return self
end

function Image:setPxXy(x,y,color)
    x,y = round(x),round(y)
    if x < 1 or x > self.sx or v < 1 or v > self.sy then
        return self
    end
    local index = xyToIndex(self.sx,x,y)
    self:registerColor(color,index)
    self.data[index] = color
    self.modified = true
    return self
end

--[[

	Samples the image to find unique colors used in it.
    Used by Image:findPalette.

	findUniqueColors(
        self: Image
    ) -> Image

]]
function Image:findUniqueColors()
    local colorMap = {}
    local uniqueColors = {}
    for k,entries in pairs(self.colors) do
        if #entries > 0 then
            uniqueColors[#uniqueColors+1] = entries.color
        end
    end
    return uniqueColors
end

--[[
    
    finds a palette using kmeans.
    for more information on how this works : https://www.kaggle.com/code/priyamchoksi/kmeanscolorization

	findPaletteKmeans(
        self: Image
        distanceFunction: ?function | Color.distance  
        paletteSize:      ?number   | 16,
        eps:              ?number   | 0.00001, // decides when to stop the algorithm, bigger eps means faster search but worse results
        maxIteration:     ?number   | 50
    ) -> [Color]
    
]]

function Image:findPaletteKmeans(uniqueColors,paletteSize,distanceFunction,eps,maxIteration)
    local t
    if self.debug then
        t = os.clock()
        print("start findPalette")
    end
    uniqueColors = uniqueColors or self:findUniqueColors()
    distanceFunction = distanceFunction and distanceFunction or Color.distance
    maxIteration=maxIteration and maxIteration or 50
    eps = eps and eps or 0.00001
    paletteSize = paletteSize and paletteSize or 16
    local palette = {}
    for i=1,paletteSize do
        local r,g,b = term.nativePaletteColor(2^(i-1))
        local c = Color:new(r,g,b,1)
        palette[i] = c
    end
    local timeYield = os.clock()
    for _=1,maxIteration do
        if (os.clock() - timeYield > 5) then
            sleep()
        end
        local clusters = {}
        for _,c in pairs(uniqueColors) do
            local minj = 1
            local mind = distanceFunction(c,palette[1])
            for j=2,#palette do
                local d = distanceFunction(c,palette[j])
                if d < mind then
                    minj = j
                    mind = d
                end
            end
            clusters[minj] = clusters[minj] and clusters[minj] or {}
            clusters[minj][#clusters[minj]+1] = c
        end
        local calcCentroid = function(cluster)
            local mean = {0,0,0}
            local lcluster = #cluster
            if lcluster > 0 then
                for i=1,lcluster do
                    local c = cluster[i]
                    mean[1] = mean[1] + c[1]
                    mean[2] = mean[2] + c[2]
                    mean[3] = mean[3] + c[3]
                end
                mean[1] = clamp(mean[1]/lcluster)
                mean[2] = clamp(mean[2]/lcluster)
                mean[3] = clamp(mean[3]/lcluster)
            end
            return Color:new(mean[1],mean[2],mean[3],1)
        end
        local newpalette = {}
        local maxd = 0
        local i = 0
        for _,cluster in pairs(clusters) do
            i=i+1
            local c = calcCentroid(cluster)
            local d = distanceFunction(c,palette[i])
            newpalette[i]=c
            maxd = maxd<d and d or maxd
        end
        for i=1,#newpalette do
            palette[i] = newpalette[i]
        end
        if maxd < eps then
            break
        end
    end
    if self.debug then
        print("end findPalette:",os.clock()-t)
    end
    return palette
end

local function argmax(X)
    local imax = 1
    local max = X[1]
    for i,x in pairs(X) do
        if x > max then
            imax = i
            max = x
        end
    end
    return imax
end

function Image:findPaletteMedianCut(uniqueColors,paletteSize,distanceFunction)
    local lightness = 0
    local function medianCut(points,key)
        table.sort(points,function(a,b) return a[key] < b[key] end)
        local l = #points
        local mean = Color()
        local n = 0
        for i=1,#points/(2+lightness/paletteSize) do
            local col = points[1]
            mean = mean + col:clamp()
            table.remove(points,1)
            n=n+1
        end
        return mean/n
    end
    local function findRange(points,key)
        local min = math.huge
        local max = 0
        for _,c in pairs(points) do
            min = math.min(min,c[key])
            max = math.max(max,c[key])
        end
        return max-min
    end
    uniqueColors = uniqueColors or self:findUniqueColors()

    local points = {}
    for _,p in pairs(uniqueColors) do
        points[#points+1] = p
        lightness = lightness+p:value()
    end
    lightness = lightness/#points
    distanceFunction = distanceFunction and distanceFunction or Color.distance
    paletteSize = paletteSize and paletteSize or 16
    local palette = {}
    for i=1,paletteSize do
        local k = argmax{
            findRange(points,1),
            findRange(points,2),
            findRange(points,3)
        }
        palette[#palette+1] = medianCut(points,k)
        if #points == 0 then
            break
        end
    end
    return palette
end

function Image:findPalette(method,uniqueColors,paletteSize,distanceFunction,eps,maxIteration)
    method = method or "kmeans"
    if method == "mediancut" then
        return self:findPaletteMedianCut(uniqueColors,paletteSize,distanceFunction)
    elseif method == "kmeans" then
        return self:findPaletteKmeans(uniqueColors,paletteSize,distanceFunction,eps,maxIteration)
    end
    error("method needs to be either mediancut or kmeans")
end

--[[

	Applies a shader to the image.

	process(
        self: Image,
        shader: function(
            self: Image, 
            u: number, 
            v: number
        ): Color
    ): Image
    
]]
function Image:process(shader,mask)
    local t
    if self.debug then
        t = os.clock()
        print("start process")
    end
    local timeYield = os.clock()
    for i=0,self.sx-1 do
        for j=0,self.sy-1 do
            if (os.clock() - timeYield > 5) then
                sleep()
                timeYield = os.clock()
            end
            local u,v = i/(self.sx-1),j/(self.sy-1)
            if not mask or mask:getPx(u,v) then
                local color = shader(self,u,v,i+1,j+1)
                self:setPx(u,v,color)
            end
        end
    end
    if self.debug then
        print("end process:",os.clock()-t)
    end
    return self
end

--[[

	Creates a new image from a shader and a size.

	map(
        self: Image,
        shader: function,
        sx: ?number | self.sx,
        sy: ?number | self.sy
    ): Image

]]
function Image:map(shader,mask,sx,sy)
    sx = sx and sx or self.sx
    sy = sy and sy or self.sy
    local newImg = Image:new(sx,sy)
    local timeYield = os.clock()
    for i=0,sx-1 do
        for j=0,sy-1 do
            if (os.clock() - timeYield > 5) then
                sleep()
                timeYield = os.clock()
            end
            local u,v = i/(sx-1),j/(sy-1)
            local color
            if not mask or mask:getPx(u,v) then
                color = shader(self,u,v,i+1,j+1)
            else
                color = self:getPx(u,v)
            end
            newImg:setPx(u,v,color)
        end
    end
    return newImg
end

function Image:draw(args)
    args = args or {}
    local function eval(x,...)
        return type(x) == 'function' and x(...) or x
    end
    local function evalVec(u,...)
        local v = {}
        v[1] = u[1] and eval(u[1],...) or 0
        v[2] = u[2] and eval(u[2],...) or 0
        if u[3] == 'px' then
            v[1] = (v[1]-1)/(self.sx-1)
            v[2] = (v[2]-1)/(self.sy-1)
        end
        return v
    end
    local mask = args.mask or function()return true end
    local maskIsFn = type(mask) == 'function'
    local function inMask(u,v)
        if maskIsFn then
            return mask(self,u,v)
        end
        return mask:getPx(u,v)
    end
    local from = evalVec(args.from and eval(args.from,self) or {0,0})
    local to = evalVec(args.to and eval(args.to,self,from) or {1,1})
    local sx = (to[1]-from[1])*(self.sx)
    local sy = (to[2]-from[2])*(self.sy)
    local image = args.image and eval(args.image,self,sx,sy) or Image:new(sx,sy)
    if args.color then
        if type(args.color) == 'table' then
            image:process(function()return args.color end)
        else
            image:process(function(s,u,v)return args.color(self,u,v,math.min(u*sx/(self.sx)+from[1],1),math.min(1,v*sy/(self.sy)+from[2])) end)
        end
    end
    for i=0,sx do
        for j=0,sy do
            local u,v = from[1]+i/(self.sx),from[2]+j/(self.sy)
            if inMask(u,v) then
                self:setPx(u,v,image:getPx(i/sx,j/sy))
            end
        end
    end
    return self
end

function Image:value()
    return self:map(function(s,u,v)
        local k = s:getPx(u,v):value()
        return Color(k,k,k)
    end)
end

function Image:max()
    local maxCol = Color()
    local maxVal = 0
    for _,col in pairs(self.data) do
        local val = col:value()
        maxCol = maxVal > val and maxCol or col
        maxVal = math.max(maxVal,val)
    end
    return maxCol
end

--[[

	Linearizes every Color in the Image.

	linearize(
        self: Image
    ) -> Image

]]
function Image:linearize()
    return self:process(function(s,u,v)
        local px = s:getPx(u,v)
        return px:linearize()
    end)
end

--[[

	Same as linearize but with a different function

	gamma2(
        self: Image
    ) -> Image

]]
function Image:gamma2()
    return self:process(function(s,u,v)
        local px = s:getPx(u,v)
        return px:gamma2()
    end)
end

return Image
