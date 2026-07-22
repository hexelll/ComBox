local function toRemote(path)
    local fhttps = path:find("https")
    local fhttp = path:find("http")
    local prefix = fhttps and fhttps == 1 and "https" or fhttp and fhttp == 1 and "http" or ""
    if #prefix == 0 then return path end
    local i = path:sub(#("https://")+1,#path):find("/")
    return {path:sub(1,i-1),path:sub(i,#path)}
end

local function combine(dir,path)
    local fhttp = path:find("http")
    if fhttp and fhttp == 1 then 
        return path,true
    end
    dir = toRemote(dir)
    if type(dir) == "table" then
        return dir[1]..fs.combine(dir[2]:sub(#dir[2],#dir[2]) ~= '/' and fs.getDir(dir[2]) or dir[2],path),true
    end
    return fs.combine(fs.getDir(dir),path),false
end

local function getContent(path,isRemote)
    if isRemote then
        local request = http.get(path)
        if not request then
            error("no such file at remote "..path)
        end
        local content = request.readAll()
        request.close()
        return content
    end
    local fp = fs.open(path,"r")
    if not fp then error("no such file at "..path) end
    local content = fp.readAll()
    fp.close()
    return content
end

local function _import(path,dir,cache)
    cache = cache or {}
    dir = dir or shell.getRunningProgram()
    local absolutePath,isRemote = combine(dir,path)
    local content = cache[absolutePath]
    if not content then
        content = getContent(absolutePath,isRemote)
        cache[absolutePath] = content
    end
    local import = _import
    local fenv = _ENV
    local env = setmetatable({
        import=function(path,_dir,_cache)
            return _import(path,_dir or absolutePath,_cache or cache)
        end
    },{__index=fenv})
    return load(content,"@/"..path,nil,env)()
end

return _import