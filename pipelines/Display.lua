if not import then error("use import to use this file not require") end

local Renderer = import "../Renderer.lua"
local MediaParser = import "../MediaParser.lua"
local Pipeline = import "../Pipeline.lua"

return Pipeline
    :new{
        process = function(self,shader)
            self:pipe(function(s,input)
                input.image:process(shader)
                return input
            end)
            return self
        end
    }
    :prior("entry")
    :after("entry","resize")
    :before("render","dither")
    :defer("render")
    :defer("display")
    :before("render","generatePalette")