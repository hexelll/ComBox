package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local Color = require "Color"
local ImageHandler = require "ImageHandler"
local MediaParser = require "MediaParser"

local Pipeline = require('Pipeline')
local pipeline = require('pipelines.DynamicDisplay')

local gar = MediaParser:open("images/gar.qoi")

pipeline
    :defer(function (_,input)
        print("elapsed time: "..input.elapsedTime)
    end)
    :start{
        paletteMethod="mediancut",
        combinators={
            --"FastCharCombinator",
            "SquarePixelCombinator"
        },
        term=peripheral.find("monitor"),
        preGenerate=20,
        time=20,
        refreshRate=1/12,
        makeImage=function(input,t)
            return Pipeline:new()
                :pipe("image")
                :pipe(function(_,input)
                    input.image:process(function(self,u,v)
                        return gar:getPx(u,v)*(0.4+(1+math.sin(t*2))/2/(math.sqrt((u-0.5)*(u-0.5)+(v-0.5)*(v-0.5))*4))
                        --return Color(u,v,(1+math.sin(t))/2)
                    end)
                    return input
                end)
                :pipe("palette")
                :pipe("dither")
                --:pipe("maskEdge")
                :pipe("render")
                :start(input)
                .render
        end
    }