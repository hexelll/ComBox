return function(_,input)
    input.render = input
        .screen
        :render(input.image,input.screen.palette)
    return input
end