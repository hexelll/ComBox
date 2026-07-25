return function(_,input,alias)
    local args = input[alias]
    input.image = input.image or args.image
    if input.image and args[1] then
        input.image = input.image:map(args[1],input.masks[args[2]])
    end
    return input
end