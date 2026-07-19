return function(_,input)
    if input.image then
        input.resize = input.resize or {}
        local method = input.resize.method or "mean"
        local sx = input.resize.sx or input.sx
        local sy = input.resize.sx or input.sy
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