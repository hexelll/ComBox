if not import then error("use import to use this file not require") end

local Renderer = import "../Renderer.lua"
local MediaParser = import "../MediaParser.lua"
local Pipeline = import "../Pipeline.lua"

return Pipeline:new()
    :prior("entry")
    :defer("render")
    :defer("display")
    :before("render","generatePalette")