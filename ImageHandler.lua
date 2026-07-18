--[[

    Used to represent Images, with many utils.
    Pixel data is a in a big array of Color objects.
    Uses UV coordinates as numbers in the [0,1] range

    ImageHandler: {
        sx: number,
        sy: number,
        data: [Color],
        uniqueColors: [Color], // initialised as {} by ImageHandler:new()
        debug: bool
    }

]]
local fp = fs.open("/.combox_secrets","r")
local path = fp.readAll()
fp.close()

package.path = package.path .. ";"..path.."?.lua" -- this is used so we can require from another directory
local Color = require("Color")

local ImageHandler = {}


local function round(x)
    return math.floor(x+0.4999)
end

local function clamp(x)
    return math.min(math.max(x,0),1)
end

-- internal util to calculate indexes in data
local function uvToIndex(sx,sy,u,v)
    local x,y = round(u*(sx-1)) , round(v*(sy-1))
    return y*sx + x + 1
end

--[[

	Creates new instance of ImageHandler.

	new(
        self:  ImageHandler
		sx:    number,        // x size
        sy:    number,        // y size
        data:  ?[Color],      // Array of pixel Colors, 
                              // if nil : filled with transparent Black ( Color:new(0,0,0,0) )
        debug: ?bool | false         
	): ImageHandler
    
]]
function ImageHandler:new(sx,sy,data,debug)

    local sx,sy = math.max(sx,0),math.max(sy,0)

    if (not data) then
        data = {}
        for i=1,sx*sy do
            data[i] = Color:new(0,0,0,0)
        end
    end

    local o = {sx=sx,sy=sy,data=data,uniqueColors={},debug=debug,modified=true}

    setmetatable(o,{
        __index=function(_,k)
            return self[k]
        end
    })

    return o
end

--[[

	Copies the image by reference

	copy(
        self: ImageHandler
    ) -> ImageHandler

]]
function ImageHandler:copy()
    local newData = {}
    for i=1,self.sx*self.sy do
        newData[i] = self.data[i]
    end

    local img = ImageHandler:new(self.sx,self.sy,newData)
    return img
end

--[[

	Same as copy but doesn't keep the original's Color objects.
    All Colors in the image will be truly duplicated, 
    not just referenced.

	duplicate(
        self: ImageHandler
    ) -> ImageHandler

]]
function ImageHandler:duplicate()
    local newData = {}
    for i=1,self.sx*self.sy do
        newData[i] = self.data[i]:duplicate()
    end

    local img = ImageHandler:new(self.sx,self.sy,newData)
    return img
end

--[[

    Resizes the image using nearest-neighbor sampling.
    Fast and preserves hard edges, but may appear jagged when scaled.

	resize(
        self: ImageHandler,
        newSx: number, 
        newSy: number   
    ) -> ImageHandler

]]
function ImageHandler:resize(newSx, newSy)
    local newData = {}
    for i=0,newSx-1 do
        for j=0,newSy-1 do
            local u,v = i/(newSx-1),j/(newSy-1)
            newData[uvToIndex(newSx,newSy,u,v)] = self:getPx(u,v)
        end
    end
    self.data = newData
    self.sx = newSx
    self.sy = newSy
    return self
end

--[[

	Resizes the image while keeping more detail then ImageHandler.resize but is much slower.
    Each pixel in the resized image is the average Color of a region of pixels from the original image.
    This is smoother than resize() but also slower and less crisp.

	resizeMean(
        self: ImageHandler,
        newSx: number, 
        newSy: number   
    ) -> ImageHandler

]]
function ImageHandler:resizeMean(newSx,newSy)
    local newData = {}
    if newSx > self.sx or newSy > self.sy then
        return self:resize(newSx,newSy)
    end
    local dx = round(self.sx/newSx)
    local dy = round(self.sy/newSy)
    
    for i=0,self.sx-1 do
        for j=0,self.sy-1 do
            local cs = Color()
            local k = 0
            for di=0,dx do
                for dj=0,dy do
                    local u,v = (i+di)/(self.sx-1),(j+dj)/(self.sy-1)
                    if u <= 1 and v <= 1 then
                        local px = self:getPx(u,v)
                        if px then
                            cs[1] = cs[1] + px[1]
                            cs[2] = cs[2] + px[2]
                            cs[3] = cs[3] + px[3]
                            k=k+1
                        end
                    end
                end
            end
            cs[1] = k > 0 and cs[1]/k or 0
            cs[2] = k > 0 and cs[2]/k or 0
            cs[3] = k > 0 and cs[3]/k or 0
            local u,v = (i)/(self.sx-1),(j)/(self.sy-1)
            newData[uvToIndex(newSx,newSy,u,v)] = cs
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
        self: ImageHandler,
        u: number, 
        v: number   
    ) -> Color

]]
function ImageHandler:getPx(u,v)
    local index = uvToIndex(self.sx,self.sy,u,v)
    return self.data[index]
end

--[[

	Sets the Color at a specific point (u,v) of the image.

	setPx(
        self: ImageHandler,
        u: number, 
        v: number,
        color: Color // new color for the point
    ) -> ImageHandler

]]
function ImageHandler:setPx(u,v,color)
    local index = uvToIndex(self.sx,self.sy,u,v)
    self.data[index] = color
    self.modified = true
    return self
end

--[[

	Samples the image to find unique colors used in it.
    Fills self.uniqueColors with these Colors.
    Used by ImageHandler:findPalette.

	findUniqueColors(
        self: ImageHandler,
        interval: ?number | 0.01, // how close the samples are taken (step in u,v)
    ) -> ImageHandler

]]
function ImageHandler:findUniqueColors(interval)
    interval = interval or 0.01
    self.uniqueColors = {}
    for u=0,1,interval do
        for v=0,1,interval do
            local color = self:getPx(u,v)
            self.uniqueColors[color:toHex()] = color
        end
    end
    return self
end

--[[
    
    finds a palette using kmeans.
    for more information on how this works : https://www.kaggle.com/code/priyamchoksi/kmeanscolorization

	findPaletteKmeans(
        self: ImageHandler
        distanceFunction: ?function | Color.distance  
        paletteSize:      ?number   | 16,
        eps:              ?number   | 0.00001, // decides when to stop the algorithm, bigger eps means faster search but worse results
        maxIteration:     ?number   | 50
    ) -> [Color]
    
]]
function ImageHandler:findPaletteKmeans(paletteSize,distanceFunction,eps,maxIteration)
    local t
    if self.debug then
        t = os.clock()
        print("start findPalette")
    end
    self:findUniqueColors()
    distanceFunction = distanceFunction and distanceFunction or Color.distance
    maxIteration=maxIteration and maxIteration or 50
    eps=eps and eps or 0.00001
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
        for _,c in pairs(self.uniqueColors) do
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

function ImageHandler:findPaletteMedianCut(paletteSize,distanceFunction)
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
    self:findUniqueColors()
    local points = {}
    for _,p in pairs(self.uniqueColors) do
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

function ImageHandler:findPalette(method,paletteSize,distanceFunction,eps,maxIteration)
    method = method or "kmeans"
    if method == "mediancut" then
        return self:findPaletteMedianCut(paletteSize,distanceFunction)
    elseif method == "kmeans" then
        return self:findPaletteKmeans(paletteSize,distanceFunction,eps,maxIteration)
    end
    error("method needs to be either mediancut or kmeans")
end

--[[

	Applies a shader to the image.

	process(
        self: ImageHandler,
        shader: function(
            self: ImageHandler, 
            u: number, 
            v: number
        ): Color
    ): ImageHandler
    
]]
function ImageHandler:process(shader)
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
            local color = shader(self,u,v)
            self:setPx(u,v,color)
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
        self: ImageHandler,
        shader: function,
        sx: ?number | self.sx,
        sy: ?number | self.sy
    ): ImageHandler

]]
function ImageHandler:map(shader,sx,sy)
    sx = sx and sx or self.sx
    sy = sy and sy or self.sy
    local newImg = ImageHandler:new(sx,sy)
    local timeYield = os.clock()
    for i=0,sx-1 do
        for j=0,sy-1 do
            if (os.clock() - timeYield > 5) then
                sleep()
                timeYield = os.clock()
            end
            local u,v = i/(sx-1),j/(sy-1)
            local color = shader(self,u,v)
            newImg:setPx(u,v,color)
        end
    end
    return newImg
end

function ImageHandler:value()
    return self:map(function(s,u,v)
        local k = s:getPx(u,v):value()
        return Color(k,k,k)
    end)
end

function ImageHandler:max()
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
        self: ImageHandler
    ) -> ImageHandler

]]
function ImageHandler:linearize()
    return self:process(function(s,u,v)
        local px = s:getPx(u,v)
        return px:linearize()
    end)
end

--[[

	Same as linearize but with a different function

	gamma2(
        self: ImageHandler
    ) -> ImageHandler

]]
function ImageHandler:gamma2()
    return self:process(function(s,u,v)
        local px = s:getPx(u,v)
        return px:gamma2()
    end)
end

return ImageHandler
