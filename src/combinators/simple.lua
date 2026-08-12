--[[

    A fast combinator used for the simplest possible rendering logic :
    Using texels as rectangle "pixels" filled with a solid color.

    This is worse than SquarePixelCombinator in most situations,
    as it has less resolution and isn't much faster.
    It is mainly meant to be an understandable exemple of how combinators work.

    SimpleCombinator: {
        name: string,
        new: function,
        onPaletteChange: function,
        onImageChange: function,
        findCombination: function
    }

]]

local Color = import "../Color.lua"

local combinator = {name="SimpleCombinator",type='combinator'}

local hexTable = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"}


local function round(x)
    return math.floor(x+0.4999)
end

--[[

    this function creates a new SimpleCombinator instance, 
    this should generaly only be done once per program

    function new(
        self: SimpleCombinator,
        args:{
            cacheSize: ?number | 100
        }
    ) -> SimpleCombinator

]]
function combinator:new(args)
    --[[ args {
        cacheSize = int
    } ]]
    args = args and args or {}
    local o = {}

    o.cacheSize = args.cacheSize and args.cacheSize or 100
    o.cache = {}

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
        self: SimpleCombinator,
        palette: [Color],
        renderer: Renderer
    ) -> void

]]
function combinator:onPaletteChange()
    self.cache = {}
end

--[[

    this function is called by Renderer when the image is different from last Renderer.render call

    onImageChange(
        self: SimpleCombinator,
        image: ImageHandler,
        palette: [Color],
        renderer: Renderer
    ) -> void

]]
function combinator:onImageChange()

end

--[[

    this function is used in Renderer to turn image information into actual characters displayed on the monitor
    it returns an array of size 3 in this format : 
    [character to display, palette index in hex format for the text color, palette index in hex format for the background color]

    findCombination(
        self: SimpleCombinator,
        u: number, 
        v: number, 
        image: ImageHandler, 
        palette: [Color]
    ) -> [char, char, char]

]]
function combinator:findCombination(u,v,image,palette)
    local px = image:getPx(u,v)

    local index = px:toHash(self.cacheSize)

    local cacheResult = self.cache[index]
    if ( cacheResult ) then
        return cacheResult
    else  
        local indexColor = px:findClosest(palette)

        local combination = {string.char(0),"0",hexTable[indexColor]}
        self.cache[index] = combination
        return combination
    end
end

return combinator