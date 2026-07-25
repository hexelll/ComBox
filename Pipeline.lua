if not import then error("use import to use this file not require") end

local Pipeline = {}

function Pipeline:new(args)
    local o = args or {}
    o.prioritized = o.prioritized or {}
    o.pipes = o.pipes or {}
    o.defered = o.defered or {}
    o.befores = o.befores or {}
    o.afters = o.afters or {}
    setmetatable(o,{
        __index = function(_,k)
            return self[k] or function(s,alias,default) return s:pipe(k,alias,default) end
        end,
        __call = function(t,input)
            return t:start(input)
        end,
        __add = function(t,b)
            return t:pipe(b)
        end,
        __mul = function(t,b)
            return t:prior(b)
        end,
        __sub = function(t,b)
            return t:defer(b)
        end
    })
    return o
end

function Pipeline.makePipe(pipe,alias,default)
    default = type(alias) == 'table' and alias or default
    default = default or {}
    return type(pipe) == "string" and {import("./pipes/"..pipe..".lua"),alias or pipe,default} 
    or type(pipe) == "table" and {pipe[1],alias or pipe[2],default} 
    or {pipe,alias,default}
end

-- pipe: (input: any): any
function Pipeline:prior(pipe,alias,default)
    self.prioritized[#self.prioritized+1] = self.makePipe(pipe,alias,default)
    return self
end

-- pipe: (input: any): any
function Pipeline:pipe(pipe,alias,default)
    self.pipes[#self.pipes+1] = self.makePipe(pipe,alias,default)
    return self
end

function Pipeline:loop(n,pipe,alias,default)
    for i=1,n do
        self:pipe(pipe,alias,default)
    end
    return self
end

-- pipe: (input: any): any
function Pipeline:defer(pipe,alias,default)
    self.defered[#self.defered+1] = self.makePipe(pipe,alias,default)
    return self
end

function Pipeline:before(pipeAlias,pipe,alias,default)
    self.befores[pipeAlias] = self.befores[pipeAlias] or {}
    table.insert(self.befores[pipeAlias],self.makePipe(pipe,default,alias))
    return self
end

function Pipeline:after(pipeAlias,pipe,alias,default)
    self.afters[pipeAlias] = self.afters[pipeAlias] or {}
    table.insert(self.afters[pipeAlias],self.makePipe(pipe,default,alias))
    return self
end

function Pipeline:remove(pipeAlias)
    for i,pipe in pairs(self.prioritized) do
        if pipe[2] == pipeAlias then
            table.remove(self.prioritized,i)
        end
    end
    for i,pipe in pairs(self.pipes) do
        if pipe[2] == pipeAlias then
            table.remove(self.pipes,i)
        end
    end
    for i,pipe in pairs(self.defered) do
        if pipe[2] == pipeAlias then
            table.remove(self.defered,i)
        end
    end
    for i,pipes in pairs(self.befores) do
        for i,pipe in pairs(pipes) do
            if pipe[2] == pipeAlias then
                table.remove(pipes,i)
            end
        end
    end
    for _,pipes in pairs(self.afters) do
        for i,pipe in pairs(pipes) do
            if pipe[2] == pipeAlias then
                table.remove(pipes,i)
            end
        end
    end
    return self
end

function Pipeline:disable(pipeAlias)
    self:before("each",function(_,input,pipe)
        if pipe[2] == pipeAlias then
            pipe[1] = function(_,input) return input end
            pipe[2] = "removed"
        end
        return input
    end)
    return self
end

function Pipeline:runPipe(pipe,input,pipeType)
    local output = input and input or {}
    local befores = self.befores[pipe[2]]
    if befores then
        for _,bpipe in pairs(befores) do
            output = self:runPipe(bpipe,output,"before")
        end
    end
    local beforeEach = self.befores["each"]
    if beforeEach then
        for _,bepipe in pairs(beforeEach) do
            output = bepipe[1](self,output,pipe,pipeType)
        end
    end

    if pipe[2] then
        output[pipe[2]] = output[pipe[2]] or {}
        local o = output[pipe[2]]
        for k,v in pairs(pipe[3]) do
            if not o[k] then
                o[k] = v
            end
        end
    end
    output = pipe[1](self,output,pipe[2],pipeType)

    local afterEach = self.afters["each"]
    if afterEach then
        for _,aepipe in pairs(afterEach) do
            output = aepipe[1](self,output,pipe,pipeType)
        end
    end
    local afters = self.afters[pipe[2]]
    if afters then
        for _,apipe in pairs(afters) do
            output = self:runPipe(apipe,output,"after")
        end
    end
    return output
end

function Pipeline:start(input)
    local output = input or {}
    local beforeAll = self.befores["all"]
    if beforeAll then
        for _,pipe in pairs(beforeAll) do
            output = pipe[1](self,input)
        end
    end
    for _,pipe in pairs(self.prioritized) do
        output = self:runPipe(pipe,input,"prior")
    end
    for _,pipe in pairs(self.pipes) do
        output = self:runPipe(pipe,input,"pipe")
    end
    for _,pipe in pairs(self.defered) do
        output = self:runPipe(pipe,input,"defer")
    end
    local afterAll = self.afters["all"]
    if afterAll then
        for _,pipe in pairs(afterAll) do
            output = pipe[1](self,input)
        end
    end
    return output
end

local tstart

function Pipeline:debug()
    self:before("each",function(_,input,pipe,pipeType)
        print(pipeType.." :",pipe[2] or 'pipe')
        tstart = os.clock()
        return input
    end)
    :after("each",function(_,input)
        print("took "..(os.clock()-tstart).."s")
        return input
    end)
    return self
end

return Pipeline