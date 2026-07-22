--[[

    This is a combinator meant to follow the coutours of the image,
    it works by detecting high changes in color and finding the angle of that change
    and assigning that angle to a character

    CharCombinator: {
        name: string,
        new: function,
        onPaletteChange: function,
        onImageChange: function,
        findCombination: function
    }

]]


local Color = import "../Color.lua"

local patterns = {
    {0,'|'},
    {math.pi,'|'},
    {math.pi/2,'='},
    {math.pi*3/4,'\\'},
    {math.pi/4,'/'},
    {math.pi/3,'-'},
    {math.pi*2/3,'-'}
}

local hexTable = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"}

local combinator = {name="FlowCombinator"}


--[[

    this function creates a new FlowCombinator instance, 
    this should generaly only be done once per program

    function new(
        self: FlowCombinator,
        args:{
            cacheSize: ?number | 100,
            limit: ?number | 0.2, // this is the threshold that determines when a change is big enough to use a coutour character
            defaultchar: ?char | "*", // this is the character that will be displayed when there is not enough change in color
            patterns: ?[ [number,char] ]  // this is the table that associates an angle from 0 to pi to a character
        }
    ) -> FlowCombinator

]]
function combinator:new(args)
    args = args and args or {}
    local o = {}
    o.invert = args.invert
    o.limit = args.limit and args.limit or 0.2
    o.defaultchar = args.defaultchar and args.defaultchar or '*'
    o.patterns = args.patterns and args.patterns or patterns
    setmetatable(o,{__index=self})
    return o
end

--[[

    this function is called when the palette is different from last Renderer.render call

    onPaletteChange(
        self: FlowCombinator,
        palette: [Color],
        renderer: Renderer
    ) -> void

]]
function combinator:onPaletteChange(palette,renderer)

end

--[[

    this function is called by Renderer when the image is different from last Renderer.render call

    onImageChange(
        self: FlowCombinator,
        image: ImageHandler,
        palette: [Color],
        renderer: Renderer
    ) -> void

]]
function combinator:onImageChange(image,palette,renderer)

end

local function findClosest(self,x,y)
    local mini = 1
    local angle = (math.atan2(y,x))%math.pi
    local mind = math.abs(self.patterns[1][1]-angle)
    for i=2,#self.patterns do
        local d =  math.abs(self.patterns[i][1]-angle)
        if d < mind then
            mind = d
            mini = i
        end
    end
    return self.patterns[mini]
end


--[[

    this function is used in Renderer to turn image information into actual characters displayed on the monitor
    it returns an array of size 3 in this format : 
    [character to display, palette index in hex format for the text color, palette index in hex format for the background color]

    findCombination(
        self: FlowCombinator,
        u: number, 
        v: number, 
        image: ImageHandler, 
        palette: [Color]
    ) -> [char, char, char]

]]
function combinator:findCombination(u,v,image,palette,renderer)
    local vx = 0
    local vy = 0
    local color = image:getPx(u,v)
    for x=-1,1 do
        for y=-1,1 do
            ku,kv = x/(renderer.sx-1),y/(renderer.sy-1)
            local px = image:getPx(u+ku,v+kv)
            px = px and px or color
            local d = color:distance(px)
            vx = vx + x*d
            vy = vy + y*d
        end
    end
    local l = math.sqrt(vx*vx+vy*vy)
    local char = self.defaultchar
    if l > self.limit then
        vx = vx/l
        vy = vy/l
        char = findClosest(self,vx,vy)[2]
    end
    local fg = hexTable[Color:new():findClosest(palette)]
    local bg = hexTable[color:findClosest(palette)]
    if not self.invert then
        fg,bg=bg,fg
    end
    return {char,fg,bg}
end

return combinator