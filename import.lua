local function toRemote(path)
    local fhttps = path:find("https")
    local fhttp = path:find("http")
    local prefix = fhttps and fhttps == 1 and "https" or fhttp and fhttp == 1 and "http" or ""
    if #prefix == 0 then return path end
    local i = path:sub(#("https://")+1,#path):find("/")
    return {path:sub(1,i-1),path:sub(i,#path)}
end

local function toDir(path)
    return path:sub(#path,#path) ~= '/' and fs.getDir(path) or path
end

local function combine(dir,path,downloadDir)
    path = toRemote(path)
    if type(path) == "table" then 
        return path[1]..path[2],true,downloadDir and fs.combine(downloadDir,path[2])
    end
    dir = toRemote(dir)
    if type(dir) == "table" then
        return 
            dir[1]..fs.combine(toDir(dir[2]),path),
            true,
            downloadDir and fs.combine(downloadDir,path)
    end
    return fs.combine(toDir(dir),path),false
end

local function getContent(path,isRemote,downloadPath)
    if isRemote then
        if downloadPath then
            local fp = fs.open(downloadPath,"r")
            if fp then
                local content = fp.readAll()
                fp.close()
                return content
            end
        end
        local request = http.get(path)
        if not request then error("no such file at remote "..path)end
        local content = request.readAll()
        request.close()
        if downloadPath then
            local fp = fs.open(downloadPath,"w")
            fp.write(content)
            fp.close()
        end
        return content
    end
    local fp = fs.open(path,"r")
    if not fp then error("no such file at "..path) end
    local content = fp.readAll()
    fp.close()
    return content
end


local function sanitizeDir(dir)
    dir = dir:sub(#dir,#dir) ~= '/' and dir..'/' or dir
    dir = dir:sub(1,1) ~= '/' and '/'..dir or dir
    return dir
end

local import = {}

function import:new(args)
    args = args or {}
    local o = {}
    o.cache = args.cache or {}
    o.dir = args.dir or sanitizeDir('/'..fs.getDir(shell.getRunningProgram()))
    o.downloadDir = args.downloadDir and sanitizeDir(args.downloadDir)
    setmetatable(o,{
        __call=function(_,...)
            return o:import(...)
        end,
        __index=function(_,k)
            return self[k]
        end
    })
    return o
end


-- dir can be an url
function import:setDir(dir)
    if dir:find("http") ~= nil then
        self.dir = dir
        return self
    end
    self.dir = dir:sub(1,1) == '/' and dir or fs.combine(self.dir,dir)
    self.dir = sanitizeDir(self.dir)
    return self
end

function import:setDownloadDir(dir)
    self.downloadDir = dir:sub(1,1) == '/' and dir or fs.combine(self.dir,dir)
    self.downloadDir = sanitizeDir(self.downloadDir)
    return self
end

function import:resetCache(cache)
    self.cache = {}
    return self
end

function import:import(path,dir,cache,downloadDir)
    cache = cache or self.cache
    dir = path:sub(1,1) == '/' and '/' or dir and dir or self.dir
    downloadDir = downloadDir or self.downloadDir
    local absolutePath,isRemote,downloadPath = combine(dir,path,downloadDir)
    local out = cache[absolutePath]
    if out then
        return out
    end
    local content = getContent(absolutePath,isRemote,downloadPath)
    cache[absolutePath] = content
    local env = setmetatable({
        import=import:new{dir=absolutePath,downloadDir=downloadPath and toDir(downloadPath),cache=cache}
    },{__index=_ENV})
    cache[absolutePath] = load(content,"@/"..path,nil,env)()
    return cache[absolutePath]
end

return import:new()