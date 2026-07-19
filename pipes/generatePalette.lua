return function(_,input,alias)
    local generatePalette = input[alias] or {}
    input.screen.palette = input.palette or input.image:findPalette(generatePalette.method,generatePalette.size)
    return input
end