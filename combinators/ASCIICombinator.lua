--[[

    this is a combinator meant to achieve a classic retro ascii look
    it works by using the lightness of the pixel as an index into a table of characters

    ASCIICombinator: {
        name: string,
        new: function,
        onPaletteChange: function,
        onImageChange: function,
        findCombination: function
    }

]]



local Color = require "Color"
local chars = {
    ' ','.','*','+','=','a','@'
}

local hexTable = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"}

local combinator = {name="ASCIIcombinator"}

--[[

    this function creates a new ASCIICombinator instance, 
    this should generaly only be done once per program

    function new(
        self: ASCIICombinator,
        args:{
            cacheSize: ?number | 100,
            chars: ?[char] | chars,
            invert: ?boolean | false
        }
    ) -> ASCIICombinator

]]
function combinator:new(args)
    args = args and args or {}
    local o = {
        cacheSize = args.cacheSize and args.cacheSize or 100,
        chars = args.chars and args.chars or chars,
        invert = args.invert
    }
    setmetatable(o,{__index=self})
    return o
end


--[[

    this function is called when the palette is different from last Renderer.render call

    onPaletteChange(
        self: ASCIICombinator,
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
        self: ASCIICombinator,
        image: ImageHandler,
        palette: [Color],
        renderer: Renderer
    ) -> void

]]
function combinator:onImageChange(image,palette,renderer)

end

local function round(x)
    return math.floor(x+0.4999)
end

--[[

    this function is used in Renderer to turn image information into actual characters displayed on the monitor
    it returns an array of size 3 in this format : 
    [character to display, palette index in hex format for the text color, palette index in hex format for the background color]

    findCombination(
        self: ASCIICombinator,
        u: number, 
        v: number, 
        image: ImageHandler, 
        palette: [Color]
    ) -> [char, char, char]

]]
function combinator:findCombination(u,v,image,palette)
    local px = image:getPx(u,v)
    px = px and px or Color()
    local col = Color()
    local hash = col:toHash(self.cacheSize)
    local cachedCol = self.cache[hash]
    if cacheCol then
        return cacheCol
    end
    local k = (px[1]+px[2]+px[3])/3
    if self.invert then
        k = 1-k
    end
    k = math.max(0,math.min(k,1))
    
    local c = 1
    col[1] = math.max(0,math.min(px[1]*c,1))
    col[2] = math.max(0,math.min(px[2]*c,1))
    col[3] = math.max(0,math.min(px[3]*c,1))
    
    local combination = {self.chars[1+round(k*(#chars-1))],hexTable[col:findClosest(palette)],hexTable[Color():findClosest(palette)]}
    if self.invert then
        combination[2],combination[3] = combination[3],combination[2]
    end
    self.cache[hash] = combination
    return combination
end

return combinator