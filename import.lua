local function _import(path,dir)
    dir = dir or shell.getRunningProgram()
    local absolutePath = fs.combine(fs.getDir(dir),path)
    local fp = fs.open(absolutePath,"r")
    if not fp then error("no such file at "..absolutePath) end
    local code = fp.readAll()
    fp.close()
    local import = _import
    local fenv = _ENV
    local env = setmetatable({
        import=function(path,_dir) 
            return _import(path,_dir or absolutePath)
        end
    },{__index=fenv})
    return load(code,"@/"..path,nil,env)()
end

return _import