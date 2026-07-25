return function(_,input,alias)
    local args = input[alias]
    if input.image and args[1] then
        input.image:process(args[1],input.masks[args[2]])
    end
    return input
end