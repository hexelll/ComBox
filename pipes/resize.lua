return function(self,input,alias)
    if input.image then
        local resize = input[alias] or {}
        if resize.disable then
            return input
        end
        local method = resize.method or "mean"
        local sx = resize.sx or input.sx
        local sy = resize.sx or input.sy
        if method == "mean" then
            if input.image.sx ~= sx and input.image.sy ~= sy then
                input.image = input.image:resize(math.min(input.image.sx,200),math.min(input.image.sy,200)):resizeMean(sx,sy)
            end
        elseif method == "naive" then
            input.image = input.image:resize(sx,sy)
        else
            error("unknown resize method")
        end
    end
    return input
end