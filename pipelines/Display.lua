local fp = fs.open("/.combox_secrets","r")
local path = fp.readAll()
fp.close()

package.path = package.path .. ";"..path.."?.lua" -- this is used so we can require from another directory

local Renderer = require "Renderer"
local MediaParser = require "MediaParser"
local Pipeline = require "Pipeline"

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
    :after("resize","sharpen","resizeSharpen")
    :before("render","dither")
    :defer("render")
    :defer("display")
    :before("render","generatePalette")