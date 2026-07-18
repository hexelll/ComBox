local Renderer = require "Renderer"
local Color = require "Color"
local SimpleCombinator = require "SimpleCombinator":new()
local CharCombinator = require "CharCombinator":new{
    nbSearched = 10,
    cacheSize = 50,
    usedChars = {127,20,0,164,167,169,174,37,42,15,2,190,187,177,61,29,34,120,48}
}
local SquarePixelCombinator = require "SquarePixelCombinator":new(0)
local FlowCombinator = require "FlowCombinator":new()
local ASCIICombinator = require "ASCIICombinator":new()
local VerboseCombinator = require "VerboseCombinator":new({
    textColor = nil,
    backColor = Color:new(0,0,0),
    usedColors = {Color:new(1,1,1),Color:new(1,0,0),Color:new(0,1,0),"#b7b7b7","#000000","#383636"},
    usedStrings = {"white","red","green","light gray","black","dark gray"},
    stringSeparator = " ",--"\183"
    cacheSize = 100,
    cascadeRatio = 1.5
})
local PixelBoxCombinator = require "PixelBoxCombinator":new()
local MediaParser = require "MediaParser"
local ImageHandler = require "ImageHandler"
--local CharCombinator = require "RoughCharCombinator":new(20,{127,20,0,164,167,169,174,37,42,15,2,190,187,177,61,29,34,120,48})
--local VerboseCombinator = require "VerboseCombinator":new(textColor,backColor,usedColors,usedStrings,stringSeparator,cacheSize,cascadeRatio)
--local MediaParser = require "MediaParser"

local mon = peripheral.find("monitor")

local screen = Renderer:new{term=mon,combinators={
    -- SquarePixelCombinator,
    PixelBoxCombinator,
    -- FlowCombinator,
    -- ASCIICombinator,
    -- SimpleCombinator,
    -- VerboseCombinator
}}

function testAllCombs(self,u,v)
    --return Color:new(ASCIICombinator)--[[
    local k = 1/#screen.combinators
    local n = 0
    for i=1,#screen.combinators do
        if u <= i*k then
            return Color:new(screen.combinators[i])
        end
    end
    return Color:new(SimpleCombinator)
end

screen.mask = ImageHandler:new(screen.sx,screen.sy):process(testAllCombs)

local function round(x)
    return math.floor(x+0.5)
end

local image = MediaParser:open(arg[1])
--[[local image = ImageHandler:new(screen.sx,round(screen.sy*3/2)):process(function(self,u,v)
    u=u*3/2
    local k = math.random()
    return Color(k,k,k)
end)]]
local palette = image:findPalette()
screen:render(image,palette):display()