return function(_,input,alias)
    local generatePalette = input[alias] or {}
    if generatePalette.disable then
        return input
    end
    input.screen.palette = input.palette or input.image:findPalette(generatePalette.method,generatePalette.uniqueColors,generatePalette.size)
    return input
end