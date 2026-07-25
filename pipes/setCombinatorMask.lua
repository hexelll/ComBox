return function(_,input,alias)
    local args = input[alias]
    if args[1] then
        input.screen.mask = input.masks[args[1]]
    end
    return input
end