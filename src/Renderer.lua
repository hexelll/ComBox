if not import then error("use import to use this file not require") end

local Color = import "./color.lua"
local ImageHandler = import "./image.lua"

local function round(x)
    return math.floor(x+0.4999)
end


local Renderer = {}

--[[

	Creates new Renderer instance.
    Given every combinator instance used by the render (so their on...Change() can be called).
    Given a mask to define which combinator to use for every texel in the render.
    The mask is an ImageHandler with the same size as the Renderer,
    filled with combinators (same instances as given in combinator).

	new(
		self: Renderer,
        args:{
            term:        ?terminal/monitor | term                         
            combinators: [Combinator],                      // array of instances of any Combinators, must contain at least one
            sx:          ?number | term.width               // x size
            sy:          ?number | term.height              // y size
            px:          ?number | 0                        // x position
            py:          ?number | 0                        // y position
            mask:        ?ImageHandler | [ combinators[1] ] // mask
            debug:       bool
        }       
	) -> Renderer

]]
function Renderer:new(params)
    local o = {}
    o.term = params.term and params.term or term
    o.combinators = params.combinators and params.combinators or error("no combinators given")
    for i,c in pairs(o.combinators) do
        if type(c) == "string" then
            o.combinators[i] = import("./combinators/"..c..".lua"):new()
        end
    end
    local width,height = o.term.getSize()
    o.sx,o.sy = params.sx and params.sx or width, params.sy and params.sy or height
    o.sx,o.sy = round(o.sx),round(o.sy)
    o.mask = params.mask
    o.px,o.py = params.px and params.px or 0, params.py and params.py or 0
    o.debug = params.debug
    if not o.mask then
        local sx,sy = self.getSize(o)
        o.mask = ImageHandler:new(sx,sy,o.combinators[1])
    end
    setmetatable(o,{
        __index=function(_,k)
            return self[k]
        end
    })
    return o
end

function Renderer:getSize()
    local sx,sy = self.sx,self.sy
    for _,c in pairs(self.combinators) do
        if c.ratio then
            sx = math.max(sx,math.floor(0.5+self.sx*c.ratio.x))
            sy = math.max(sx,math.floor(0.5+self.sy*c.ratio.y))
        end
    end
    return sx,sy
end

--[[

    sets the combinator to be used at a point on the screen

    setMaskAt(
        self: Renderer,
        u: number,
        v: number,
        combinator: Combinator
    ) -> Renderer

]]
function Renderer:setMaskAt(u,v,combinator)
    self.mask:setPx(u,v,combinator)
    return self
end

--[[

    changes the size of the renderer and its mask

    resize(
        self: Renderer,
        sx: number,
        sy: number
    ) -> Renderer

]]
function Renderer:resize(sx,sy)
    self.sx = sx
    self.sy = sy
    self.mask:resize(sx,sy)
    return self
end

--[[

    returns the combinator at a point on the screen

    setMaskAt(
        self: Renderer,
        u: number,
        v: number
    ) -> Renderer

]]
function Renderer:getCombinator(u,v)
    local c = self.mask:getPx(u,v)
    if type(c) == 'number' then
        return self.combinators[c]
    elseif type(c) == 'table' then
        return c
    end
    error('not a combinator at '..u..' '..v)
end

--[[

    computes the characters to be drawn to a terminal.
    it returns the lines of character to blit and 
    a display function that can be used to display the image to the renderer term

    render(
        self: Renderer,
        image: ImageHandler,
        palette: ?[Color] | image:findPalette()
    ) -> {
        lines: [ [char,char,char] ],
        display: function()->Renderer
    }

]]
function Renderer:render(image,palette)
    local t
    if self.debug then
        t = os.clock()
        print("start render")
    end
    if not palette and image.modified then
        palette = image:findPalette()
        image.modified = false
        for _,combinator in pairs(self.combinators) do
            combinator:onImageChange(image,palette,self)
        end
    end
    palette = palette and palette or self.lastPalette
    local equal = true
    if self.lastPalette then
        for i=1,#palette do
            if not (self.lastPalette[i] == palette[i]) then
                equal = false
                break
            end
        end
    else
        equal = false
    end
    if not equal then
        for _,combinator in pairs(self.combinators) do
            combinator:onPaletteChange(palette,self)
        end
    end
    
    self.lastPalette = palette
    self.palette = palette
    local timeYield = os.clock()
    local lines = {}
    for i=1,self.sy do
        lines[i] = {{},{},{}}
        for j=1,self.sx do
            if ( os.clock() > timeYield+5 ) then
                sleep()
                timeYield = os.clock()
            end
            local t1 = os.clock()
            local v,u = (i-1)/((self.sy-1)),(j-1)/((self.sx-1))
            local combinator = self:getCombinator(u,v)
            if not combinator then 
                error("no combinator at uv ("..u..","..v..")") 
            end
            local combination = combinator:findCombination(u,v,image,palette,self)
            if not combination then
                error("combination is nil at uv ("..u..","..v..") with "..combinator.name)
            end
            if not combination[1] or not combination[2] or not combination[2] then
                error("error in combination at uv ("..u..","..v..") with "..combinator.name.." combination [1]:"..combination[1].." [2]:"..combination[2].." [3]:"..combination[3])
            end
            lines[i][1][j] = combination[1]
            lines[i][2][j] = combination[2]
            lines[i][3][j] = combination[3]
        end
        lines[i][1] = table.concat(lines[i][1])
        lines[i][2] = table.concat(lines[i][2])
        lines[i][3] = table.concat(lines[i][3])
    end
    if self.debug then
        print("end render:",os.clock()-t)
    end
    return {
        lines=lines,
        palette=palette,
        sx=self.sx,
        sy=self.sy,
        px=self.px,
        py=self.py,
        display=function()
            self:display(lines,palette)
        return self
    end}
end

--[[

    displays an array of lines to the renderer term

    display(
        self: Renderer,
        lines: [ [char,char,char] ],
        palette?: [ Color ]
    ) -> Renderer

]]
function Renderer:display(lines,palette)
    local t
    if self.debug then
        t = os.clock()
        print("start display")
    end
    local palette = palette or self.palette
    for i=1,#palette do
        self.term.setPaletteColor(2^(i-1),palette[i][1],palette[i][2],palette[i][3])
    end
    for i=1,self.sy do
        self.term.setCursorPos(1+self.px,i+self.py)
        self.term.blit(table.unpack(lines[i]))
    end
    if self.debug then
        print("end display:",os.clock()-t)
    end
    return self
end

return Renderer