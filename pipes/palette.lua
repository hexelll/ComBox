return function(_,input)
    input.palette = input.palette or {}
    input.screen.palette = input.image:findPalette(input.palette.method,input.palette.size)
    return input
end