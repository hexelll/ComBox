local drawTri = import 'drawTri.lua'

return function(self,input,alias)
    local args = input[alias]
    input = self:runPipe(
        {
            drawTri,
            alias..'_tri1',
            {
                points={
                    args.points[2],
                    args.points[3],
                    args.points[1]
                },
                color=function(u,v,w,U,V,input)
                    return args.color(u/(u+v+w),v/(u+v+w),U,V,input)
                end
            }
        },input)
    input = self:runPipe(
        {
            drawTri,
            alias..'_tri2',
            {
                points={
                    args.points[2],
                    args.points[3],
                    args.points[4]
                },
                color=function(u,v,w,U,V,input)
                    return args.color(1-v/(u+v+w),1-u/(u+v+w),U,V,input)
                end
            }
        },input)
    return input
end