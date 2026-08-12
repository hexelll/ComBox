local Color = require("Color")

local SmoothCharCombinator = {name="SmoothCharCombinator"}

local hexTable = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"}

local charCoefs = {
    0 ,
    19/54 ,
    25/54 ,
    21/54 ,
    13/54 ,
    19/54 ,
    18/54 ,
    12/54 ,
    36/54 ,
    0 ,
    0 ,
    14/54 ,
    17/54 ,
    0 ,
    15/54 ,
    22/54 ,
    13/54 ,
    13/54 ,
    20/54 ,
    12/54 ,
    19/54 ,
    20/54 ,
    8/54 ,
    24/54 ,
    13/54 ,
    13/54 ,
    11/54 ,
    11/54 ,
    7/54 ,
    10/54 ,
    13/54 ,
    13/54 ,
    0 ,
    6/54 ,
    6/54 ,
    20/54 ,
    15/54 ,
    11/54 ,
    15/54 ,
    3/54 ,
    9/54 ,
    9/54 ,
    6/54 ,
    9/54 ,
    3/54 ,
    5/54 ,
    2/54 ,
    7/54 ,
    19/54 ,
    12/54 ,
    16/54 ,
    14/54 ,
    15/54 ,
    17/54 ,
    15/54 ,
    12/54 ,
    17/54 ,
    15/54 ,
    4/54 ,
    5/54 ,
    7/54 ,
    10/54 ,
    7/54 ,
    14/54 ,
    24/54 ,
    18/54 ,
    20/54 ,
    13/54 ,
    18/54 ,
    17/54 ,
    13/54 ,
    17/54 ,
    17/54 ,
    11/54 ,
    10/54 ,
    15/54 ,
    11/54 ,
    17/54 ,
    17/54 ,
    16/54 ,
    14/54 ,
    16/54 ,
    18/54 ,
    15/54 ,
    11/54 ,
    15/54 ,
    13/54 ,
    17/54 ,
    13/54 ,
    9/54 ,
    15/54 ,
    11/54 ,
    7/54 ,
    11/54 ,
    5/54 ,
    5/54 ,
    3/54 ,
    14/54 ,
    16/54 ,
    11/54 ,
    16/54 ,
    15/54 ,
    11/54 ,
    17/54 ,
    14/54 ,
    6/54 ,
    11/54 ,
    12/54 ,
    7/54 ,
    13/54 ,
    12/54 ,
    12/54 ,
    14/54 ,
    14/54 ,
    9/54 ,
    13/54 ,
    9/54 ,
    12/54 ,
    9/54 ,
    14/54 ,
    9/54 ,
    15/54 ,
    13/54 ,
    9/54 ,
    7/54 ,
    9/54 ,
    6/54 ,
    1/3 ,
    0 ,
    1/6 ,
    1/6 ,
    1/3 ,
    1/6 ,
    1/3 ,
    1/3 ,
    1/2 ,
    1/6 ,
    1/3 ,
    1/3 ,
    1/2 ,
    1/3 ,
    1/2 ,
    1/2 ,
    2/3 ,
    1/6 ,
    1/3 ,
    1/3 ,
    1/2 ,
    1/3 ,
    1/2 ,
    1/2 ,
    2/3 ,
    1/3 ,
    1/2 ,
    1/2 ,
    2/3 ,
    1/2 ,
    2/3 ,
    2/3 ,
    5/6 ,
    0 ,
    6/54 ,
    13/54 ,
    16/54 ,
    16/54 ,
    17/54 ,
    6/54 ,
    20/54 ,
    2/54 ,
    20/54 ,
    11/54 ,
    10/54 ,
    7/54 ,
    5/54 ,
    18/54 ,
    5/54 ,
    8/54 ,
    14/54 ,
    7/54 ,
    8/54 ,
    2/54 ,
    15/54 ,
    19/54 ,
    4/54 ,
    2/54 ,
    8/54 ,
    12/54 ,
    10/54 ,
    14/54 ,
    13/54 ,
    17/54 ,
    9/54 ,
    16/54 ,
    16/54 ,
    19/54 ,
    18/54 ,
    16/54 ,
    15/54 ,
    20/54 ,
    14/54 ,
    18/54 ,
    18/54 ,
    21/54 ,
    18/54 ,
    11/54 ,
    11/54 ,
    12/54 ,
    11/54 ,
    19/54 ,
    17/54 ,
    16/54 ,
    16/54 ,
    17/54 ,
    16/54 ,
    16/54 ,
    9/54 ,
    19/54 ,
    13/54 ,
    13/54 ,
    12/54 ,
    13/54 ,
    9/54 ,
    14/54 ,
    19/54 ,
    16/54 ,
    16/54 ,
    19/54 ,
    18/54 ,
    16/54 ,
    15/54 ,
    17/54 ,
    13/54 ,
    17/54 ,
    17/54 ,
    20/54 ,
    17/54 ,
    7/54 ,
    7/54 ,
    8/54 ,
    7/54 ,
    15/54 ,
    16/54 ,
    14/54 ,
    14/54 ,
    17/54 ,
    16/54 ,
    14/54 ,
    7/54 ,
    15/54 ,
    14/54 ,
    14/54 ,
    13/54 ,
    14/54 ,
    17/54 ,
    13/54 ,
    17/54 ,
}

local function round(x)
    return math.floor(x+0.5)
end

local function clamp(x)
    return math.min(math.max(x,-1),1)
end

local function colorToIndex(c, size)
    local r = round(c[1] * (size - 1))
    local g = round(c[2] * (size - 1))
    local b = round(c[3] * (size - 1))

    return r * size * size + g * size + b
end

local function vertorCrossProduct(u,v)
    return { u[2]*v[3]-u[3]*v[2] , u[3]*v[1]-u[1]*v[3] , u[1]*v[2]-u[2]*v[1] }
end

local function vertorSub(u,v)
    return { u[1]-v[1] , u[2]-v[2] , u[3]-v[3] }
end

local function vectorNorm(c)
    return math.sqrt(c[1]*c[1] + c[2]*c[2] + c[3]*c[3])
end

local function vectorDotProduct(u,v)
    return u[1]*v[1] + u[2]*v[2] + u[3]*v[3]
end

local function findBestCharRandom(self,idealCoef)
    local bestChar = 1
    local minDif = math.huge
    local inv = false
    local closeChars = {}
    for i=1, #self.usedCharsCoef do
        local coef = self.usedCharsCoef[i]
        local dist1 = math.abs(idealCoef-coef)
        if (dist1 < minDif) then
            minDif = dist1
            bestChar = i
            inv = false
        end
        if (dist1 < self.randomDist) then
            table.insert(closeChars,{i,false})
        end
        local dist2 = math.abs(1-idealCoef-coef)
        if (dist2 < minDif) then
            minDif = dist2
            bestChar = i
            inv = true
        end
        if (dist2 < self.randomDist) then
            table.insert(closeChars,{i,true})
        end
    end
    table.insert(closeChars,{bestChar,inv})
    return closeChars[ math.random( #closeChars ) ]
end

local function findBestChar(self,idealCoef)
    local bestChar = 1
    local minDif = math.huge
    local inv = false
    for i=1, #self.usedCharsCoef do
        local coef = self.usedCharsCoef[i]
        local dist1 = math.abs(idealCoef-coef)
        if (dist1 < minDif) then
            minDif = dist1
            bestChar = i
            inv = false
        end
        local dist2 = math.abs(1-idealCoef-coef)
        if (dist2 < minDif) then
            minDif = dist2
            bestChar = i
            inv = true
        end
    end
    return {bestChar,inv}
end

function SmoothCharCombinator:new(args)
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

    o.useCache = args.useCache == nil and true or args.useCache
    o.useRandom = args.useRandom 
    o.randomDist = args.randomDist and args.randomDist or 0.05
    
    o.findBestCharFunc = o.useRandom and findBestCharRandom or findBestChar

    o.cache = {}

    o.distConsideredEqual = args.distConsideredEqual and args.distConsideredEqual or 0

    setmetatable(o,{
        __index=function(_,k)
            return self[k]
        end
    })

    return o
end

function SmoothCharCombinator:onPaletteChange(palette)
    self.cache = {}
end

function SmoothCharCombinator:onImageChange(image)

end

function SmoothCharCombinator:findCombination(u,v,image,palette)
    local searchedColor = image:getPx(u,v)

    --if (self.useCache) then
        local index = colorToIndex(searchedColor,self.cacheSize)
        local cacheResult = self.cache[index]
    --end
    if ( cacheResult ) then
        return cacheResult
    else    

        local closestColor = 1
        local closestColorDistance = searchedColor:distance(palette[1])
        for i=2,#palette do
            local dist = searchedColor:distance(palette[i])
            if dist < closestColorDistance then
                closestColorDistance = dist
                closestColor = i
            end
        end

        -- vector defining the line conecting closestColor and searchedColor
        local u = vertorSub(palette[closestColor],searchedColor)
        local normU = vectorNorm(u)

        local combination
        -- if perfect color already found
        if normU <= self.distConsideredEqual then
            combination = {string.char(0), hexTable[closestColor], hexTable[closestColor]}
        else 
        
            -- search for color opposite to closestColor compared to searchedColor
            local secondColor = closestColor
            local minDistance = math.huge
            for i,color in ipairs(palette) do
                if (i ~= closestColor) then

                    local BA = vertorSub(searchedColor,color)
                    local angle = math.acos ( clamp(vectorDotProduct(BA,u)/(vectorNorm(BA)*normU) ) )

                    if ( angle < math.pi/2 ) then
                        local dist = vectorNorm(vertorCrossProduct(BA,u)) / normU
                        if ( dist < minDistance ) then
                            minDistance = dist
                            secondColor = i
                        end
                    end
                end
            end
            if ( secondColor == closestColor ) then
                minDistance = math.huge
                for i=1,#palette do
                    if (i ~= closestColor) then
                        local dist = searchedColor:distance(palette[i])
                        if dist < minDistance then
                            minDistance = dist
                            secondColor = i
                        end
                    end
                end
            end

            -- ideal coeficient
            local idealCoef = (closestColorDistance/(minDistance+closestColorDistance))
  
            local result = self:findBestCharFunc(idealCoef)

            if (result[2])then
                combination = {string.char(self.usedChars[result[1]]),hexTable[closestColor],hexTable[secondColor]}
            else
                combination = {string.char(self.usedChars[result[1]]),hexTable[secondColor],hexTable[closestColor]}
            end
        end
        if (self.useCache) then
            self.cache[index] = combination
        end
        return combination
    end
end

return SmoothCharCombinator