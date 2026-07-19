return function(self,input,alias)
    if input.image then
        local resize = input[alias] or {}
        if resize.disable then
            return input
        end
        local method = resize.method or "mean"
        local sx = resize.sx or input.sx
        local sy = resize.sx or input.sy
        input.resizeSharpen = input.resizeSharpen or {}
        if method == "mean" then
            input.image = input.image:resize(math.max(sx,200),math.max(sy,200)):resizeMean(sx,sy)
            input.resizeSharpen.disable = input.resizeSharpen.disable == nil and false or input.resizeSharpen.disable
        elseif method == "naive" then
            input.image = input.image:resize(sx,sy)
            input.resizeSharpen.disable = input.resizeSharpen.disable == nil and true or input.resizeSharpen.disable
        else
            error("unknown resize method")
        end
    end
    return input
end