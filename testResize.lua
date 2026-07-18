local combox = require "combox"
local ImageHandler = combox.ImageHandler 
local Renderer = combox.Renderer
local Color = combox.Color

local FastCharCombinator = require "combinators.SquarePixelCombinator":new()

local screen = Renderer:new{
    combinators={FastCharCombinator}
}

local image = ImageHandler:new(10,10):process(function(self,u,v)
    return Color(u,v)
end)

image:resizeMean(screen.sx,screen.sy)

screen:render(image):display()