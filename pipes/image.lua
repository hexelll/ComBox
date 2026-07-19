local fp = fs.open("/.combox_secrets","r")
local path = fp.readAll()
fp.close()

package.path = package.path .. ";"..path.."?.lua" -- this is used so we can require from another directory

local ImageHandler = require "ImageHandler"

return function(_,input,alias)
    local image = input[alias] or {}
    if image.disable then
        return input
    end
    input.image = ImageHandler:new(input.sx,input.sy)
    return input
end