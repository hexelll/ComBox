return function(_,input,alias)
    if input.image then
        local resize = input[alias] or {}
        local method = resize.method or "mean"
        local sx = resize.sx or input.sx
        local sy = resize.sx or input.sy
        if method == "mean" then
            input.image = input.image:resizeMean(sx,sy)
        elseif method == "naive" then
            input.image = input.image:resize(sx,sy)
        else
            error("unknown resize method")
        end
    end
    return input
end