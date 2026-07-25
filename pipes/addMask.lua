local ImageHandler = import '../ImageHandler.lua'

return function(_,input,alias)
    local args = input[alias]
    input.masks = input.masks or {}
    if type(args[1]) == 'table' then
        input.masks[alias] = args[1]
    end
    if type(args[1]) == 'function' then
        input.masks[alias] = ImageHandler:new(input.sx,input.sy,true):process(args[1])
    end
    return input
end