if not import then error("use import to use this file not require") end

local ImageHandler = import "../ImageHandler.lua"

return function(_,input,alias)
    local image = input[alias] or {}
    if image.disable then
        return input
    end
    input.image = ImageHandler:new(input.sx,input.sy)
    return input
end