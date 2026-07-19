return function(_,input,alias)
    local render = input[alias] or {}
    if render.disable then
        return input
    end
    input.render = input
        .screen
        :render(input.image,input.screen.palette)
    return input
end