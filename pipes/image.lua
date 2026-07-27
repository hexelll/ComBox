if not import then error("use import to use this file not require") end

local ImageHandler = import "../ImageHandler.lua"

-- {at={0,function(_,input) return math.sin(os.clock()) end},sx=4,sy=10,
--         image=function(_,input,alias)
--             Texture(input.image)
--                 :drawLine{
--                     from={0,0},
--                     to={10,10,'px'},
--                     -- u,v relatifs à l'élément
--                     color=function(self,u,v,t) -- self = {from,to,image,...}
--                         return Color(t,t,t)
--                     end
--                 }
--                 :drawRectangle{
--                     from={0,0},
--                     to={0.5,0.5},
--                     -- u,v relatifs à l'élément
--                     color=function(self,u,v) -- self = {from,to,image,...}
--                         return Color(u,v)
--                     end
--                 }
--                 :drawText{
--                     at={0.5,0.5},
--                     -- u,v relatifs à l'élément
--                     color=function(self,u,v,c) -- self = {at,image,...}
--                         return Color(u,v)
--                     end
--                 }
--         end
--     }

return function(self,input,alias)
    local args = input[alias] or {}
    if args.disable then
        return input
    end
    local image = args.image
    if type(image) == 'function' then
        image = image(self,input,alias)
    end
    if not image then
        image = ImageHandler:new(input.sx,input.sy)
    end
    args.image = image
    input.image:draw(args)
    return input
end