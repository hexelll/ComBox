local fp = fs.open("/.combox_secrets","r")
local path = fp.readAll()
fp.close()

package.path = package.path .. ";"..path.."?.lua" -- this is used so we can require from another directory

local Pipeline = {}

function Pipeline:new(args)
    local o = args or {}
    o.prioritized = o.prioritized or {}
    o.pipes = o.pipes or {}
    o.defered = o.defered or {}
    o.befores = o.befores or {}
    setmetatable(o,{
        __index = function(_,k)
            return self[k]
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

function Pipeline.makePipe(pipe)
    return type(pipe) == "string" and {require("pipes."..pipe),pipe} or type(pipe) == "table" and pipe or {pipe}
end

-- pipe: (input: any): any
function Pipeline:prior(pipe)
    self.prioritized[#self.prioritized+1] = self.makePipe(pipe)
    return self
end

-- pipe: (input: any): any
function Pipeline:pipe(pipe)
    self.pipes[#self.pipes+1] = self.makePipe(pipe)
    return self
end

-- pipe: (input: any): any
function Pipeline:defer(pipe)
    self.defered[#self.defered+1] = self.makePipe(pipe)
    return self
end

function Pipeline:before(pipeAlias,pipe)
    self.befores[pipeAlias] = self.befores[pipeAlias] or {}
    table.insert(self.befores[pipeAlias],self.makePipe(pipe))
    return self
end

function Pipeline:runPipe(pipe,input)
    local output = input and input or {}
    local befores = self.befores[pipe[2]]
    if befores then
        for _,bpipe in pairs(befores) do
            output = self:runPipe(bpipe,output)
        end
    end
    return pipe[1](self,output)
end

function Pipeline:start(input)
    local output = input
    for _,pipe in pairs(self.prioritized) do
        output = self:runPipe(pipe,input)
    end
    for _,pipe in pairs(self.pipes) do
        output = self:runPipe(pipe,input)
    end
    for _,pipe in pairs(self.defered) do
        output = self:runPipe(pipe,input)
    end
    return output
end

return Pipeline