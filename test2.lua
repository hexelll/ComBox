local combox = require "comboxVirtual" -- this would also work without using comboxVirtual
    local FastCharCombinator = combox.combinators.FastCharCombinator:new() -- we create a new FastCharCombinator instance, we don't give it a parameters table so it will use the default
    local screen = combox.Renderer:new{
        combinators = {FastCharCombinator} -- we define what combinator we want to use
    }

    local image = combox.ImageHandler:new(screen.sx,screen.sy) -- we create an image with the same size as our screen
    image:process(function(self,u,v) -- we apply a shader to our image, see ImageHandler.lua for more info
        return combox.Color(u,v) -- equivalent to Color:new(u,v,0,1)
    end) 

    screen:render(image) -- we calculate all the combination to display on our screen
    .display() -- we display the combinations from render