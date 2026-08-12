--[[

    This combinator will write text on screen depending on the desired color of the texel.
    It can be used to spell out colors where they appear or describe elements on the image.
    This is not meant to create high fidelity renders of images, but it is very funny.

    VerboseCombinator: {
        name: string,
        new: function,
        onPaletteChange: function,
        onImageChange: function,
        findCombination: function
    }

]]

local Color = import "../Color.lua"

local combinator = {name="VerboseCombinator",type='combinator'}

local hexTable = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"}


--[[
    Math Utils
]]
local function round(x)
    return math.floor(x+0.4999)
end

local function clamp(x)
    return math.min(math.max(x,0),1)
end


--[[

    this function creates a new VerboseCombinator instance, 
    this should generaly only be done once per program

    function new(
        self: VerboseCombinator,
        args:{
            cacheSize:          ?number                 | 100,
            textColor:          Color/number/function               // if given Color : constantly will use the closest color in the palette from given Color
                                                                    // if given number : uses the number as coeficient to brighten/darken the image color, then uses closest color in palette to that
                                                                    // if given function : uses call of function with args (pixelColor,palette,image,renderer,u,v) as index to use in the palette, for every texel
                                                                    // if nil : uses findClosest from pixelColor (same as given number 1)

            backColor:          Color/number/function               // exact same as textColor
            
            usedColors:         [Color/String]          | {"FF0000","00FF00","0000FF","FFFFFF","000000"}    // array of Colors to be associated to String to display (can be given HEX codes as Strings too), Nth Color is associated with Nth String in usedStrings
            usedStrings:        [String]                | {"red","green","blue","white","black"}            // array of String to be associated to Colors to display, Nth String is associated with Nth Color in usedColors
            
            stringSeparator:    ?String                 | " "       // the string that will seperate every string in used usedStrings (to avoid repeating the separator at the end of every String)
            shiftToEdges:       ?bool                   | false     // if the text will restart from the begining on edges (color change)
            edgeSeparator:      ?char/String            | ""        // the char/ 1 length String that will appear on edges (color change)
            cascadeRatio:       ?number                 | 0         // by how much the text will be shifted by every line (prevents ugly vertical alignements)
        }
    ) -> VerboseCombinator

]]
function combinator:new(args)
    args = args and args or {}
        
    local o = {}

    local typeTextColor = type(args.textColor)
    if ( typeTextColor == "table" )then
        o.desiredTextColor = args.textColor

    elseif ( typeTextColor == "number" ) then
        o.textColorShader = function (pixelColor,palette)
            local r,g,b = table.unpack(pixelColor)
            return Color:new(clamp(r*args.textColor),clamp(g*args.textColor),clamp(b*args.textColor)):findClosest(palette)
        end

    elseif ( typeTextColor == "function" ) then
        o.textColorShader = args.textColor
    end

    local typeBackColor = type(args.backColor)
    if ( typeBackColor == "table" )then
        o.desiredBackColor = args.backColor

    elseif ( typeBackColor == "number" ) then
        o.backColorShader = function (pixelColor,palette)
            local r,g,b = table.unpack(pixelColor)
            return Color:new(clamp(r*args.backColor),clamp(g*args.backColor),clamp(b*args.backColor)):findClosest(palette)
        end

    elseif ( typeBackColor == "function" ) then
        o.backColorShader = args.backColor
    end

    o.usedColors = args.usedColors and args.usedColors or {"FF0000","00FF00","0000FF","FFFFFF","000000"}
    for i, color in ipairs(o.usedColors) do
        if (type(color)=="string") then
            o.usedColors[i] = Color.fromHex(color)
        end
    end

    o.usedStrings = args.usedStrings and args.usedStrings or {"red","green","blue","white","black"}
    if (args.stringSeparator) then
        for i, string in ipairs(o.usedStrings) do
            o.usedStrings[i] = string..args.stringSeparator 
        end
    end
    o.stringSeparator = args.stringSeparator and args.stringSeparator or " "

    o.shiftToEdges = args.shiftToEdges
    if (o.shiftToEdges) then
        o.edgeSeparator = args.edgeSeparator and string.sub(args.edgeSeparator,1,1) or ""
        o.edgeSeperatorSize = o.edgeSeparator:len()
        o.lastBoundaryPosition = math.huge
        o.lastBoundaryStringIndex = -1
    end

    o.cascadeRatio = args.cascadeRatio and args.cascadeRatio or 0

    o.cache = {}
    o.cacheSize = args.cacheSize and args.cacheSize or 100

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
        self: VerboseCombinator,
        palette: [Color],
        renderer: Renderer
    ) -> void

]]
function combinator:onPaletteChange(palette)
    self.usedTextColorIndex = self.desiredTextColor and self.desiredTextColor:findClosest(palette) or nil
    self.usedBackColorIndex = self.desiredBackColor and self.desiredBackColor:findClosest(palette) or nil

    self.cache = {}
end

--[[

    this function is called by Renderer when the image is different from last Renderer.render call

    onImageChange(
        self: VerboseCombinator,
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
        self: VerboseCombinator,
        u: number, 
        v: number, 
        image: ImageHandler, 
        palette: [Color]
    ) -> [char, char, char]

]]
function combinator:findCombination(u,v,image,palette,renderer)
    local pixelColor = image:getPx(u,v)

    local indexT,indexB

    -- find text and back color
    local index = pixelColor:toHash(self.cacheSize)
    local cacheResult = self.cache[index]
    if ( cacheResult ) then
        indexT,indexB = table.unpack(cacheResult)
    else  

        indexT = self.usedTextColorIndex 
        if ( not indexT )then
            if ( self.textColorShader) then
                indexT = self.textColorShader(pixelColor,palette,image,renderer,u,v)
            else
                indexT = pixelColor:findClosest(palette)
            end
        end

        indexB = self.usedBackColorIndex 
        if ( not indexB ) then
            if (self.backColorShader) then
                indexB = self.backColorShader(pixelColor,palette,image,renderer,u,v)
            else
                indexB = pixelColor:findClosest(palette)
            end
        end

        self.cache[index] = {indexT,indexB}
    end

    -- find char
    local usedStringIndex = self.usedColors and pixelColor:findClosest(self.usedColors) or nil ;
    local char = ' ';
    if ( usedStringIndex ) then 
        local usedString = self.usedStrings[usedStringIndex]

        if (self.shiftToEdges) then

            local i

            local texelPosition = u*(renderer.sx-1)
            
            if ( texelPosition < self.lastBoundaryPosition) then
                self.lastBoundaryPosition = texelPosition 
                self.lastBoundaryStringIndex = usedStringIndex
            end
            if (usedStringIndex ~= self.lastBoundaryStringIndex) then
                self.lastBoundaryPosition = texelPosition 
                self.lastBoundaryStringIndex = usedStringIndex

                if (self.edgeSeperatorSize ~= 0) then
                    char = self.edgeSeparator
                else
                    i = round( texelPosition - self.lastBoundaryPosition + self.cascadeRatio*v*(renderer.sy-1) ) % usedString:len() +1
                    char = string.sub(usedString,i,i)
                end
            else
                local offset = self.lastBoundaryPosition == 0 and 0 or self.edgeSeperatorSize
                i = round( texelPosition - self.lastBoundaryPosition -offset + self.cascadeRatio*v*(renderer.sy-1) ) % usedString:len() +1
                char = string.sub(usedString,i,i)
            end

            
        else 
            local i = round( u* (renderer.sx-1) + self.cascadeRatio*v*(renderer.sy-1)  ) % usedString:len() +1
            char = string.sub(usedString,i,i)
        end 
        
    end
    
    return {char,hexTable[indexT],hexTable[indexB]}
end

return combinator