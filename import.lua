local function _import(path,dir)
    local sdir = shell.dir()
    dir = dir or shell.getRunningProgram()
    shell.setDir(fs.getDir(dir))
    local absolutePath = "/"..shell.resolve(path)
    local fp = fs.open(absolutePath,"r")
    if not fp then error("no such file at "..absolutePath) end
    local code = fp.readAll()
    fp.close()
    local import = _import
    local fenv = getfenv()
    local env = setmetatable({
        import=function(path,_dir) 
            return _import(path,_dir or absolutePath)
        end
    },{__index=fenv})
    shell.setDir(sdir)
    return load(code,"@/"..path,nil,env)()
end

return _import