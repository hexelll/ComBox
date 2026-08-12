package.path = package.path .. ";../?.lua" -- this is used so we can require from a parent directory

local Color = require "Color"
local Renderer = require "Renderer"
local ImageHandler = require "ImageHandler"

local combinator = require("combinators.FastCharCombinator"):new()

local mon = peripheral.find('monitor')

if mon then
    mon.setTextScale(0.5)
end


local screen = Renderer:new{
    term=mon,
    combinators={combinator}
}

local state = {
    boids = {},
    avoidrange = 0.005,
    attractrange = 0.02,
    alignrange = 0.03,
    typerange = 0.01,
    avoidance = 5,
    attraction = 0.5,
    alignment = 0.5,
    n=300
}

function state:makeBoids()
    self.boids = {}
    boids = self.boids
    for i = 1,self.n do
        local px = math.random()
        local py = math.random()
        local dx = math.random(0,0.99)+0.01
        local dy = math.random(0,0.99)+0.01
        local l = math.sqrt(dx*dx+dy*dy)
        dx = dx/l
        dy = dy/l
        boids[i] = {
            x=px,
            y=py,
            type=math.floor(math.random(1,3)+0.5),
            v=0.2,
            dir={x=dx,y=dy}
        }
    end
end

function state:updateBoids(dt)
    for i=1,self.n do
        local boid = self.boids[i]
        local avoidx = 0
        local avoidy = 0
        local attractx = 0
        local attracty = 0
        local alignx = 0
        local aligny = 0
        local k1 = 0
        local k2 = 0
        local k3 = 0
        for j=1,self.n do 
            if i ~= j then
                local other = self.boids[j]
                local r = ((other.x-boid.x)*(other.x-boid.x)+(other.y-boid.y)*(other.y-boid.y))
                if r < self.typerange then
                    if boid.type ~= other.type then
                        avoidx = avoidx + (boid.x-other.x)*4
                        avoidy = avoidy + (boid.y-other.y)*4
                        k1=k1+1
                    else
                        if r < self.avoidrange then
                            avoidx = avoidx + (boid.x-other.x)
                            avoidy = avoidy + (boid.y-other.y)
                            k1=k1+1
                        end
                        if r < self.attractrange then
                            attractx = attractx + other.x
                            attracty = attracty + other.y
                            k2=k2+1
                        end
                        if r < self.alignrange then
                            alignx = alignx + other.dir.x
                            aligny = aligny + other.dir.y
                            k3=k3+1
                        end
                    end
                end
            end
        end

        if state.dangerx and state.dangery then
            local r = (state.dangerx-boid.x)*(state.dangerx-boid.x)+(state.dangery-boid.y)*(state.dangery-boid.y)
            if r < 0.02 then
                boid.dir.x = (boid.x-state.dangerx)*2
                boid.dir.y = (boid.y-state.dangery)*2
            end
        end

        if k1 > 0 then
            local avoiddirx = avoidx+0.001
            local avoiddiry = avoidy+0.001
            boid.dir.x = boid.dir.x + avoiddirx*self.avoidance
            boid.dir.y = boid.dir.y + avoiddiry*self.avoidance
        end
        if k2 > 0 then
            local attractdirx = boid.x-attractx/k2
            local attractdiry = boid.y-attracty/k2

            boid.dir.x = boid.dir.x - attractdirx*self.attraction
            boid.dir.y = boid.dir.y - attractdiry*self.attraction
        end
        if k3 > 0 then
            aligndirx = alignx/k3 + 0.001
            aligndiry = aligny/k3 + 0.001
            boid.dir.x = boid.dir.x + aligndirx*self.alignment
            boid.dir.y = boid.dir.y + aligndiry*self.alignment
        end

        if boid.x < 0.1 then
            boid.dir.x = boid.dir.x+10*(1-boid.x)
        end
        if boid.x > 0.9 then
            boid.dir.x = boid.dir.x-10*boid.x
        end
        if boid.y < 0.1 then
            boid.dir.y = boid.dir.y+10*(1-boid.y)
        end
        if boid.y > 0.9 then
            boid.dir.y = boid.dir.y-10*boid.y
        end

        l = math.sqrt(boid.dir.x*boid.dir.x+boid.dir.y*boid.dir.y)
        boid.dir.x = boid.dir.x/l
        boid.dir.y = boid.dir.y/l
        
    end
    for i=1,self.n do
        local boid = self.boids[i]
        boid.x = boid.x + boid.v*boid.dir.x*dt
        boid.y = boid.y + boid.v*boid.dir.y*dt
    end
end


state:makeBoids()

lastt = os.clock()

parallel.waitForAll(
    function()
        while true do
            local image = ImageHandler:new(screen.sx,math.floor(screen.sy*3/2+0.5)):process(
                function(self,u,v)
                    local col = Color()
                    for i = 1,state.n do
                        local b = state.boids[i]
                        local r = (b.x-u)*(b.x-u)+(b.y-v)*(b.y-v)
                        if r < 0.001 then
                            k = 1-r*1/0.001
                            k =k * 0.3
                            if b.type == 1 then
                                col = col + Color(k)
                            elseif b.type == 2 then
                                col = col + Color(0,k)
                            else
                                col = col + Color(0,0,k)
                            end
                        end
                        if r <= 1/(1+self.sx*self.sx+self.sy*self.sy) then
                            --col = Color(1,1,1)
                        end
                    end
                    col[1] = math.min(1,col[1])
                    col[2] = math.min(1,col[2])
                    col[3] = math.min(1,col[3])
                    return col
                end
            )
            
            screen:render(image).display()
            --print("render")
            sleep()
        end
    end,
    function()
        while true do
            local t = os.clock()
            local dt = t-lastt
            lastt = t
            state:updateBoids(dt)
            --print("update")
            sleep()
        end
    end,
    function()
        while true do
            local _,_,mx,my = os.pullEvent("monitor_touch")
            state.dangerx = mx/screen.sx
            state.dangery = my/screen.sy
        end
    end
)