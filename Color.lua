--[[

    Used to represent colors, 
    Offers many utils for computation with colors.
    r,g,b,a are mainly intended to be in 0-1

    Color: {
        [1] : number, // r
        [2] : number, // g
        [3] : number, // b
        [4] : number, // a
        new: function,
        distance: function,
        findClosest: function,
        toOklab: function,
        distanceOklab: function,
        fromHex: function,
        toHex: function,
        duplicate: function,
        linearize: function,
        gamma2: function,
        toHash: function
    }

]]

local Color = {}

local hexTable = {
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f"
}
-- reverse of hexTable
local hexTableI = {
    ["0"] = 0,
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["a"] = 10,
    ["b"] = 11,
    ["c"] = 12,
    ["d"] = 13,
    ["e"] = 14,
    ["f"] = 15
}

local function round(x)
    return math.floor(x+0.4999)
end

local function clamp(x)
    return math.min(math.max(x,0),1)
end

--[[
	Creates new instance of Color.
    Can be given r,g,b,a or Hex as a String.
    You can also use Color(r,g,b,a) instead.
    r,g,b,a are intended to be in 0-1

	new(
		r: ?number/String    | 0,    // if number : red
                                     // if String : parsed as Hex with Color.fromHex(r), g,b and a are ignored
        g: ?number           | 0,    // green
        b: ?number           | 0,    // blue
        a: ?number           | 1,    // alpha
	): Color
]]
function Color:new(r,g,b,a)
    if type(r) == "string" then
        return Color.fromHex(r)
    end
    r = r and r or 0
    g = g and g or 0
    b = b and b or 0
    a = a and a or 1
    local o = {r,g,b,a}
    setmetatable(o,{
        __index=function(_,k)   
            return self[k]
        end,
        -- to String format : (r,g,b,a) rounded to 0.01
        __tostring=function(s)
            return "("..(round(s[1]*100)/100)..","..(round(s[2]*100)/100)..","..(round(s[3]*100)/100)..","..(round(s[4]*100)/100)..")"
        end,

        -- Math operations :
        -- applies operation component by component, except alpha

        -- Substraction : 
        __sub=function(a,b)
            if type(a) == "number" and type(b) == "table" then
                return Color:new(a-b[1],a-b[2],a-b[3],a-b[4])
            end
            if type(a) == "table" and type(b) == "number" then
                return Color:new(a[1]-b,a[2]-b,a[3]-b,a[4]-b)
            end
            if type(a) == "table" and type(b) == "table" then
                return Color:new(a[1]-b[1],a[2]-b[2],a[3]-b[3],a[4]-b[4])
            end
        end,
        -- Addition : 
        __add=function(a,b)
            if type(a) == "number" and type(b) == "table" then
                a,b=b,a
            end
            if type(a) == "table" and type(b) == "number" then
                return Color:new(a[1]+b,a[2]+b,a[3]+b,a[4]+b)
            end
            if type(a) == "table" and type(b) == "table" then
                return Color:new(a[1]+b[1],a[2]+b[2],a[3]+b[3],a[4]+b[4])
            end
        end,
        -- Multiplication :
        __mul=function(a,b)
            if type(a) == "number" and type(b) == "table" then
                a,b=b,a
            end
            if type(a) == "table" and type(b) == "number" then
                return Color:new(a[1]*b,a[2]*b,a[3]*b,a[4])
            end
            if type(a) == "table" and type(b) == "table" then
                return Color:new(a[1]*b[1],a[2]*b[2],a[3]*b[3],a[4]*b[4])
            end
        end,
        __div=function(a,b)
            if type(a) == "number" and type(b) == "table" then
                return Color:new(b/a[1],b/a[2],b/a[3],a[4])
            end
            if type(a) == "table" and type(b) == "number" then
                return Color:new(a[1]/b,a[2]/b,a[3]/b,a[4])
            end
            if type(a) == "table" and type(b) == "table" then
                return Color:new(a[1]/b[1],a[2]/b[2],a[3]/b[3],a[4]/b[4])
            end
        end,

        -- Equality : two colors are equal if : r1=r2 and g1=g2 and b1=b2
        __eq=function(a,b)
            return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
        end,
        __unm=function(a)
            return Color(-a[1],-a[2],-a[3])
        end
    })
    return o
end

--[[
	Basic distance between two colors (self and given Color).

	distance(
		color: Color, // the other Color
	): number
]]
function Color:distance(color)
    local s1,s2,s3,c1,c2,c3 = self[1],self[2],self[3],color[1],color[2],color[3]
    return (s1-c1)*(s1-c1)+(s2-c2)*(s2-c2)+(s3-c3)*(s3-c3)
end

-- interpolation util
local function interp(a,b,k)
    return a*(1-k)+b*k
end
--[[
	Mix two colors (self and given Color) with a single coefficient.
    (1-k) represents "how much" of self to use.

	mix(
        self: Color,
		color: Color,
        k: number,    // coeficient for the mix
	): Color
]]
function Color:mix(color,k)
    k = k or 0.5
    return Color:new(interp(self[1],color[1],k),interp(self[2],color[2],k),interp(self[3],color[3],k),interp(self[4],color[4],k))
end

--[[
	Finds the closest color in palette to self and returns its index.

	findClosest(
        self: Color
		palette: [Color],           
        distanceFunction: ?function | Color.distance, // the function used to rank palette colors
        palettesize: ?number | #palette,              // can be given palettesize to reduce calls to #palette
	): number
]]
function Color:findClosest(palette,distanceFunction,palettesize)
    palettesize = palettesize and palettesize or #palette
    distanceFunction = distanceFunction and distanceFunction or self.distance
    local mindist = distanceFunction(self,palette[1])
    local mini = 1
    for i=2,palettesize do
        local dist = distanceFunction(self,palette[i])
        if dist < mindist then
            mindist = dist
            mini = i
        end
    end
    return mini
end

--[[
	Converts a Color to Oklab color space.
    Theoretically closer to actual human sight.
    But it is pretty slow to calculate and gives barely noticeable changes, 
    especially amongst the bigger constraints of CC displays.

	toOklab(
        self: Color
    ): Color
]]
function Color:toOklab()
    local r, g, b = self[1],self[2],self[3]

    -- Convert to Oklab
    local l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    local m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    local s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

    local l_, m_, s_ = l^(1/3), m^(1/3), s^(1/3)

    local L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    local A = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    local B = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

    -- Explicitly convert for nearly achromatic colors
    if math.abs(A) < 1e-4 then A = 0 end
    if math.abs(B) < 1e-4 then B = 0 end

    -- Normalize to appropriate range
    local k1, k2 = 0.206, 0.03
    local k3 = (1 + k1) / (1 + k2)
    L = 0.5 * (k3 * L - k1 + math.sqrt((k3 * L - k1) ^ 2 + 4 * k2 * k3 * L))
    return Color:new( 100 * L, 100 * A, 100 * B, self[4] )
end

--[[
	Color distance using Oklab color space
    Theoretically closer to actual human sight.
    But it is pretty slow to calculate and gives barely noticeable changes, 
    especially amongst the bigger constraints of CC displays.

	distanceOklab(
        self: Color
		color: Color,   // the other color         
    ): number
]]
function Color:distanceOklab(color)
    return self.distance(self:toOklab(),color:toOklab())
end

--[[
	New Color from hex.
    Supports formats with or without leading #   
    ("#RRGGBBAA" or "RRGGBBAA" or "#RRGGBB" or "RRGGBB") 

	fromHex(
		hex: String,
	): Color
]]
function Color.fromHex(hex)
    hex = string.lower(hex)
    local j = hex:sub(1,1) == "#" and 1 or 0
    local rgb = {}
    for i=0,math.floor((#hex-j)/2)-1 do
        local n = hexTableI[hex:sub(j+2*i+1,j+2*i+1)]+hexTableI[hex:sub(j+2*i+2,j+2*i+2)]*16
        rgb[i+1] = n/255
    end
    return Color:new(table.unpack(rgb))
end

--[[
	Converts a color to Hex, all lowercase.
    Doesn't handle alpha.
    Format without leading # ("ffffff")

	toHex(
        self: Color
    ): String
]]
function Color:toHex()
    self:sanitize()
    local rgb = {
        round(self[1]*255),
        round(self[2]*255),
        round(self[3]*255)
    }
    local hex = table.concat{
        hexTable[(rgb[1] % 16)+1],hexTable[(round((rgb[1]-(rgb[1] % 16))/16)%16)+1],
        hexTable[(rgb[2] % 16)+1],hexTable[(round((rgb[2]-(rgb[2] % 16))/16)%16)+1],
        hexTable[(rgb[3] % 16)+1],hexTable[(round((rgb[3]-(rgb[3] % 16))/16)%16)+1]
    }
    return hex
end

function Color:sanitize()
    self[1] = math.min(1,math.max(0,self[1] == self[1] and self[1] or 0))
    self[2] = math.min(1,math.max(0,self[2] == self[2] and self[2] or 0))
    self[3] = math.min(1,math.max(0,self[3] == self[3] and self[3] or 0))
    return self
end

--[[
	Duplicates Color.
    Allows reuse without sharing references.

	duplicate(
        self: Color
    ): Color
]]
function Color:duplicate()
    return Color:new(table.unpack(self))
end

--[[
    Linearize Color.
    Allows for "more accurate" math with colors.

	linearize(
        self: Color
    ): Color
]]
function Color:linearize()
    local col = Color()
    for i=1,3 do
        col[i] = self[i] <= 0.04045 and self[i]/12.92 or ((self[i]+0.055)/1.055)^2.4
    end
    return col
end

--[[
	Faster Color:linearize().
    Not theoretically perfect linearization but good enough for most purposes.

	gamma2(
        self: Color
    ): Color
]]
function Color:gamma2()
    return Color(self[1]^2.2,self[2]^2.2,self[3]^2.2)
end

--[[
	Maps Color to int, with int in [0, size^3 - 1]
    Size determines the precision and size of the map.
    Useful to index caches.
    Doesn't take alpha into account.

	toHash(
        self: Color
        size: number // To how many discrete values each component (r,g,b) of the Color is rounded to 
    ): number
]]
function Color:toHash(size)
    local r = math.floor(math.min(1,math.max(0,self[1]))*(size-1)+0.5)
    local g = math.floor(math.min(1,math.max(0,self[2]))*(size-1)+0.5)
    local b = math.floor(math.min(1,math.max(0,self[3]))*(size-1)+0.5)
    return r*size*size+g*size+b
end

function Color:value()
    local k = 0.30*self[1] + 0.59*self[2] + 0.11*self[3]
    return k
end

function Color:gray()
    local k = self:value()
    return Color(k,k,k)
end

function Color:sum()
    return self[1]+self[2]+self[3]
end

function Color:max()
    return math.max(self[1],self[2],self[3])
end

function Color:invert()
    return Color(1-self[1],1-self[2],1-self[3])
end

local function clamp(x,min,max)
    min = min or 0
    max = max or 1
    return math.max(min,math.min(max,x))
end

function Color:clamp(min,max)
    return Color(clamp(self[1],min,max),clamp(self[2],min,max),clamp(self[3],min,max))
end

-- Makes it so you can shorten Color:new() to just Color()
setmetatable(Color,{__call=function(self,...)
    return self:new(...)
end})

return Color
