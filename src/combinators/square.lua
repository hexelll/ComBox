--[[

    This is a combinator meant to have square pixels, this means that the size of the image you pass
    to Renderer.render should be 3/2 times larger than the screen resolution, this can be done with
    image:resize(sx,math.floor(sy*3/2)) for the smallest image possible.
    It is fast and suitable for realtime use, but it lacks in terms of color accuracy on big screens compared to
    char combinators.

    SquarePixelCombinator: {
        name: string,
        new: function,
        onPaletteChange: function,
        onImageChange: function,
        findCombination: function
    }

]]

local Color = import "../Color.lua"

local combinator = {ratio={x=1,y=3/2},type='combinator'}

local hexTable = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"}


local function round(x)
    return math.floor(x+0.4999)
end

-- cache management util
local function addToCache(self,palette,rawcol)
    local hcol = rawcol:toHash(self.cacheSize)
    if self.cache[hcol] then
        return self.cache[hcol]
    end
    local c = rawcol:findClosest(palette)
    self.cache[hcol] = c
    return c
end


--[[

    this function creates a new SquarePixelCombinator instance, 
    this should generaly only be done once per program

    function new(
        self: SquarePixelCombinator,
        args:{
            cacheSize: ?number | 100
        }
    ) -> SquarePixelCombinator

]]
function combinator:new(args)
    args = args and args or {}
    local cacheSize = args.cacheSize and args.cacheSize or 16
    local o = {cacheSize=cacheSize,cache={}}
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
        self: SquarePixelCombinator,
        palette: [Color],
        renderer: Renderer
    ) -> void

]]
function combinator:onPaletteChange(palette,renderer)
    self.cache = {}
end

--[[

    this function is called by Renderer when the image is different from last Renderer.render call

    onImageChange(
        self: SquarePixelCombinator,
        image: ImageHandler,
        palette: [Color],
        renderer: Renderer
    ) -> void

]]
function combinator:onImageChange(image,palette,renderer)

end

--[[

    this function is used in Renderer to turn image information into actual characters displayed on the monitor
    it returns an array of size 3 in this format : 
    [character to display, palette index in hex format for the text color, palette index in hex format for the background color]

    findCombination(
        self: SquarePixelCombinator,
        u: number, 
        v: number, 
        image: ImageHandler, 
        palette: [Color]
    ) -> [char, char, char]

]]
function combinator:findCombination(u,v,image,palette,renderer)
    local step = 1/(renderer.sy-1)
    local c = image:getPx(u,v) or Color()

    local combination = {}

    -- different process on even/odd rows 
    if round(v*(renderer.sy-1))%2 == 0 then
        local col = addToCache(self,palette,c)
        local othercol = image:getPx(u,v+step*2/3)
        othercol = othercol and othercol or c
        othercol = addToCache(self,palette,othercol)
        
        combination[1] = '\143'
        combination[2] = hexTable[col]
        combination[3] = hexTable[othercol]
    else
        local col = image:getPx(u,v+step/3)
        col = col and col or c
        col = addToCache(self,palette,col)
        local othercol = image:getPx(u,v-step/3)
        othercol = othercol and othercol or c
        othercol = addToCache(self,palette,othercol)
        
        combination[1] = '\131'
        combination[3] = hexTable[col]
        combination[2] = hexTable[othercol]
    end

    return combination
end

return combinator
