local fp = fs.open("/.combox_secrets","r")
local path = fp.readAll()
fp.close()

package.path = package.path .. ";"..path.."?.lua" -- this is used so we can require from another directory

local Renderer = require "Renderer"
local MediaParser = require "MediaParser"

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
    input.combinator = input.combinator or input.combinators and input.combinators[1] or require("combinators.FastCharCombinator"):new()
    input.combinators = input.combinators or {input.combinator}
    input.screen = input.screen or Renderer:new{
        term=input.term,
        combinators=input.combinators,
        sx=input.screenx,
        sy=input.screeny,
        px=input.px,
        py=input.py
    }
    input.sx,input.sy = input.sx or input.screen.sx, input.sy or input.screen.sy
    local hasSquarePixel = false
    for _,c in pairs(input.combinators) do
        if c.name == "SquarePixelCombinator" then
            input.sy = math.floor(0.5+input.sy*3/2)
        end
    end
    if input.path then
        input.image = MediaParser:open(input.path)
    end
    return input
end