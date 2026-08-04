if not import then error("use import to use this file not require") end

local Renderer = import "../Renderer.lua"
local MediaParser = import "../MediaParser.lua"
local ImageHandler = import "../ImageHandler.lua"

--[[ 
    input: {
        image?: ImageHandler, 
        path?: string, 
        screen?: Renderer, 
        term?: term, 
        combinator?: Combinator = FastCharCombinator, 
        combinators?: [Combinator], 
        resizeMean?: boolean = true
    }
]]
return function(_,input)
    input.resizeMean = input.resizeMean == nil and true or input.resizeMean
    input.combinator = input.combinator or input.combinators and input.combinators[1] or import("../combinators/FastCharCombinator.lua"):new()
    input.combinators = input.combinators or {input.combinator}
    input.screen = input.screen or Renderer:new{
        term=input.term,
        combinators=input.combinators,
        sx=input.screenx,
        sy=input.screeny,
        px=input.px,
        py=input.py
    }
    input.masks = input.masks or {}
    input.combinators = input.screen.combinators
    input.sx,input.sy = input.sx or input.screen.sx, input.sy or input.screen.sy
    input.sx,input.sy = input.screen:getSize()
    input.screen.mask = ImageHandler:new(input.sx,input.sy,input.combinators[1])
    if input.image then
        input.image = input.image:duplicate()
    elseif input.path then
        input.image = MediaParser:open(input.path)
    else
        input.image = ImageHandler:new(input.sx,input.sy)
    end
    return input
end