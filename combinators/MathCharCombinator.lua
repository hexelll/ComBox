--[[

    This is a combinator meant to find the combination that is closest to the color in the image, 
    regardless of smoothness (difference between text and background color).
    This is done by pre-compiling the segments between every palette color (represented with vectors),
    then searching for the segment that is closest to our ideal color, 
    then finaly calculating the best character for that segment.
    It is quite fast but still a bit slow for realtime use, especialy if the palette is changed frequetly.
    For smoother combinations, try FullChar (very slow) or FastChar.

    MathCharCombinator: {
        name: string,
        new: function,
        onPaletteChange: function,
        onImageChange: function,
        findCombination: function
    }

]]


local Color = import "../Color.lua"

local combinator = {name="MathCharCombinator"}

local hexTable = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"}
local charCoefs = {0 ,19/54 ,25/54 ,21/54 ,13/54 ,19/54 ,18/54 ,12/54 ,36/54 ,0 ,0 ,14/54 ,17/54 ,0 ,15/54 ,22/54 ,13/54 ,13/54 ,20/54 ,12/54 ,19/54 ,20/54 ,8/54 ,24/54 ,13/54 ,13/54 ,11/54 ,11/54 ,7/54 ,10/54 ,13/54 ,13/54 ,0 ,6/54 ,6/54 ,20/54 ,15/54 ,11/54 ,15/54 ,3/54 ,9/54 ,9/54 ,6/54 ,9/54 ,3/54 ,5/54 ,2/54 ,7/54 ,19/54 ,12/54 ,16/54 ,14/54 ,15/54 ,17/54 ,15/54 ,12/54 ,17/54 ,15/54 ,4/54 ,5/54 ,7/54 ,10/54 ,7/54 ,14/54 ,24/54 ,18/54 ,20/54 ,13/54 ,18/54 ,17/54 ,13/54 ,17/54 ,17/54 ,11/54 ,10/54 ,15/54 ,11/54 ,17/54 ,17/54 ,16/54 ,14/54 ,16/54 ,18/54 ,15/54 ,11/54 ,15/54 ,13/54 ,17/54 ,13/54 ,9/54 ,15/54 ,11/54 ,7/54 ,11/54 ,5/54 ,5/54 ,3/54 ,14/54 ,16/54 ,11/54 ,16/54 ,15/54 ,11/54 ,17/54 ,14/54 ,6/54 ,11/54 ,12/54 ,7/54 ,13/54 ,12/54 ,12/54 ,14/54 ,14/54 ,9/54 ,13/54 ,9/54 ,12/54 ,9/54 ,14/54 ,9/54 ,15/54 ,13/54 ,9/54 ,7/54 ,9/54 ,6/54 ,1/3 ,0 ,1/6 ,1/6 ,1/3 ,1/6 ,1/3 ,1/3 ,1/2 ,1/6 ,1/3 ,1/3 ,1/2 ,1/3 ,1/2 ,1/2 ,2/3 ,1/6 ,1/3 ,1/3 ,1/2 ,1/3 ,1/2 ,1/2 ,2/3 ,1/3 ,1/2 ,1/2 ,2/3 ,1/2 ,2/3 ,2/3 ,5/6 ,0 ,6/54 ,13/54 ,16/54 ,16/54 ,17/54 ,6/54 ,20/54 ,2/54 ,20/54 ,11/54 ,10/54 ,7/54 ,5/54 ,18/54 ,5/54 ,8/54 ,14/54 ,7/54 ,8/54 ,2/54 ,15/54 ,19/54 ,4/54 ,2/54 ,8/54 ,12/54 ,10/54 ,14/54 ,13/54 ,17/54 ,9/54 ,16/54 ,16/54 ,19/54 ,18/54 ,16/54 ,15/54 ,20/54 ,14/54 ,18/54 ,18/54 ,21/54 ,18/54 ,11/54 ,11/54 ,12/54 ,11/54 ,19/54 ,17/54 ,16/54 ,16/54 ,17/54 ,16/54 ,16/54 ,9/54 ,19/54 ,13/54 ,13/54 ,12/54 ,13/54 ,9/54 ,14/54 ,19/54 ,16/54 ,16/54 ,19/54 ,18/54 ,16/54 ,15/54 ,17/54 ,13/54 ,17/54 ,17/54 ,20/54 ,17/54 ,7/54 ,7/54 ,8/54 ,7/54 ,15/54 ,16/54 ,14/54 ,14/54 ,17/54 ,16/54 ,14/54 ,7/54 ,15/54 ,14/54 ,14/54 ,13/54 ,14/54 ,17/54 ,13/54 ,17/54}


--[[
    Vector Math Utils
]]
local function round(x)
    return math.floor(x+0.4999)
end

local function clamp(x)
    return math.min(math.max(x,0),1)
end

local function vectorCrossProduct(u,v)
    return { u[2]*v[3]-u[3]*v[2] , u[3]*v[1]-u[1]*v[3] , u[1]*v[2]-u[2]*v[1] }
end

local function vectorSub(u,v)
    return { u[1]-v[1] , u[2]-v[2] , u[3]-v[3] }
end

local function vectorNorm(c)
    return c[1]*c[1] + c[2]*c[2] + c[3]*c[3]
end

local function vectorDotProduct(u,v)
    return u[1]*v[1] + u[2]*v[2] + u[3]*v[3]
end

local function distSegmentColor(segment,color)
    local t = clamp( vectorDotProduct( vectorSub(color, segment[3]) , segment[4]) / segment[5] )

    local P = {
        segment[3][1] + segment[4][1]*t,
        segment[3][2] + segment[4][2]*t,
        segment[3][3] +segment[4][3]*t
    }

    return vectorNorm(vectorSub(color, P)), t
end


--[[

    this function creates a new MathCharCombinator instance, 
    this should generaly only be done once per program

    function new(
        self: MathCharCombinator,
        args:{
            cacheSize: ?number   | 100,
            usedChars: ?[number] | [0-255], // All characters to be used by the combinator, identified by their number
        }
    ) -> MathCharCombinator

]]
function combinator:new(args)
    args = args and args or {}
    local o = {}

    o.cacheSize = args.cacheSize and args.cacheSize or 100
    
    o.usedChars = args.usedChars and args.usedChars or {}
    if ( #o.usedChars == 0) then
        o.usedChars = {}
        for i=1,256 do
            o.usedChars[#o.usedChars+1] = i-1
        end
    end 

    o.usedCharsCoef = {}
    for _,charNum in ipairs(o.usedChars) do
        table.insert( o.usedCharsCoef , charCoefs[charNum+1] )
    end

    o.cache = {}

    o.preCompiledSegments = {}

    setmetatable(o,{
        __index=function(_,k)
            return self[k]
        end
    })

    return o
end

--[[

    this function is called when the palette is different from last Renderer.render call

    onPaletteChange(
        self: MathCharCombinator,
        palette: [Color],
        renderer: Renderer
    ) -> void

]]
function combinator:onPaletteChange(palette)
    self.cache = {}

    -- pre-compile segments between every color in palette
    self.preCompiledSegments = {}
    local doneColors = {}
    for i,color1 in ipairs(palette) do
        local linearC1 = color1:gamma2()
        for j,color2 in ipairs(palette) do
            local linearC2 = color2:gamma2()
            if ( not doneColors[j] and i~=j) then
                local direction = vectorSub(linearC2,linearC1)
                local directionNorm = vectorNorm(direction)
                if (directionNorm ~= 0) then
                    self.preCompiledSegments[#self.preCompiledSegments+1] = {i,j,linearC1,direction,directionNorm}
                end
            end
        end
        doneColors[i] = true
    end
end

--[[

    this function is called by Renderer when the image is different from last Renderer.render call

    onImageChange(
        self: MathCharCombinator,
        image: ImageHandler,
        palette: [Color],
        renderer: Renderer
    ) -> void

]]
function combinator:onImageChange(image)

end

--[[

    this function is used in Renderer to turn image information into actual characters displayed on the monitor
    it returns an array of size 3 in this format : 
    [character to display, palette index in hex format for the text color, palette index in hex format for the background color]

    findCombination(
        self: MathCharCombinator,
        u: number, 
        v: number, 
        image: ImageHandler, 
        palette: [Color]
    ) -> [char, char, char]

]]
function combinator:findCombination(u,v,image,palette)
    local searchedColor = image:getPx(u,v) or Color()

    -- cache 
    local index = searchedColor:toHash(self.cacheSize)
    local cacheResult = self.cache[index]
    if ( cacheResult ) then
        return cacheResult
    else    

        local linearSC = searchedColor:gamma2()

        -- find the best segment
        local bestSegment
        local minDif = math.huge
        local bestT = 0
        for i,segment in ipairs(self.preCompiledSegments)do
            local dist,t = distSegmentColor(segment,linearSC)
            
            if (dist < minDif) then
                minDif = dist
                bestT = t
                bestSegment = segment
            end
        end
        
        -- find the best char
        local bestChar = 1
        local minDif = math.huge
        local inv = false
        for i=1, #self.usedCharsCoef do
            local coef = self.usedCharsCoef[i]
            local dist1 = math.abs(bestT-coef)
            if (dist1 < minDif) then
                minDif = dist1
                bestChar = i
                inv = false
            end
            local dist2 = math.abs(1-bestT-coef)
            if (dist2 < minDif) then
                minDif = dist2
                bestChar = i
                inv = true
            end
        end

        local combination
        if (inv)then
            combination = {string.char(self.usedChars[bestChar]),hexTable[bestSegment[1]],hexTable[bestSegment[2]]}
        else
            combination = {string.char(self.usedChars[bestChar]),hexTable[bestSegment[2]],hexTable[bestSegment[1]]}
        end
        
        self.cache[index] = combination
        return combination
    end
end

return combinator