--[[
    ComBox: 
    An all-in-one rendering system for CC:Tweaked.
    All about render quality and customizability.
    
    Made by: 
    TO (@to_noaccentavailable)
    Hexell (@hexell_dev)

    How to use:
    Simply require this file, then use anything you need from the returned object like so:
        local combox = require("combox")
        local renderer = combox.Renderer 
        local image = combox.MediaParser.open("your image path") 
    By default every file you need will be downloaded from GitHub and cached in /ComBox on your computer.
    You can change where it will look for files with
        combox.import:setSourcePath('/myDirectory') or combox.import:setSourcePath('https://myRemoteSource.com')
    You can change where it will be cached with 
        combox.import:setCachePath('/myDirectory')
    > files are only cached to this path if the source is remote (url)

    For more details, check the repo: https://github.com/hexelll/ComBox
]]

local import = (function() local function a(b)local c=b:find("https")local d=b:find("http")local e=c and c==1 and"https://"or d and d==1 and"http://"or""if#e==0 then return b end;local f=#e+b:sub(#e+1,#b):find("/")return{b:sub(1,f-1),b:sub(f,#b)}end;local function g(b)return b:sub(#b,#b)~='/'and fs.getDir(b)or b end;local function h(i,b,j)b=a(b)if type(b)=="table"then return b[1]..b[2],true,j and fs.combine(j,b[2])end;i=a(i)if type(i)=="table"then return i[1]..'/'..fs.combine(g(i[2]),b),true,j and fs.combine(j,b)end;return fs.combine(g(i),b),false end;local function k(b,l,m)if l then if m then local n=fs.open(m,"r")if n then local o=n.readAll()n.close()return o end end;local p=http.get(b)if not p then error("no such file at remote "..b)end;local o=p.readAll()p.close()if m then local n=fs.open(m,"w")n.write(o)n.close()end;return o end;local n=fs.open(b,"r")if not n then error("no such file at "..b)end;local o=n.readAll()n.close()return o end;local function q(i)i=i:sub(#i,#i)~='/'and i..'/'or i;i=i:sub(1,1)~='/'and'/'..i or i;return i end;local r={}function r:new(s)s=s or{}local t={}t.cache=s.cache or{}t.dir=s.dir or q('/'..fs.getDir(shell.getRunningProgram()))t.baseDir=t.dir;t.downloadDir=s.downloadDir and q(s.downloadDir)setmetatable(t,{__call=function(u,...)return t:import(...)end,__index=function(u,v)return self[v]end})return t end;function r:setSourcePath(i)if i:find("http")~=nil then self.dir=i;return self end;local w=a(self.dir)if type(w)=='table'then self.dir=i:sub(1,1)=='/'and i or w[1]..q(fs.combine(w[2],i))else self.dir=i:sub(1,1)=='/'and i or fs.combine(w,i)self.dir=q(self.dir)end;return self end;function r:resetSourcePath()self:setDir(self.baseDir)end;function r:setCachePath(i)self.downloadDir=i:sub(1,1)=='/'and i or fs.combine(self.dir,i)self.downloadDir=q(self.downloadDir)return self end;function r:resetCache(x)self.cache={}fs.delete(self.downloadDir)return self end;function r:import(b,i,x,j)x=x or self.cache;i=b:sub(1,1)=='/'and'/'or i and i or self.dir;j=j or self.downloadDir;local y,l,m=h(i,b,j)local z=x[y]if z then return z end;local o=k(y,l,m)local A=setmetatable({import=r:new{dir=y,downloadDir=m and g(m),cache=x}},{__index=_ENV})local B,C=load(o,"@/"..y,nil,A)if C then error(C)end;x[y]=B()return x[y]end;return r:new() end)()

import
    :setCachePath("/ComBox")
    :setSourcePath("https://raw.githubusercontent.com/hexelll/ComBox/refs/heads/main/src")

return setmetatable(
    { import=import },
    {
        __index=function(self,k)
            local data = import(k .. '.lua')
            self[k] = data
            return data
        end
    }
)