return function(_,input)
    input.generatePalette = input.generatePalette or {}
    input.screen.palette = input.palette or input.image:findPalette(input.generatePalette.method,input.generatePalette.size)
    return input
end