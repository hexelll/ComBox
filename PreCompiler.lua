local PreCompiler = {}

-- internal util
local function findExtension(path)
    local i = path:find("%.")
    while i do
        path = path:sub(i+1,#path)
        i = path:find("%.")
    end
    return path
end

local function serializeLines(lines)
    local text = "{\n"
    for i=1,#lines do
        local line = lines[i]
        text = text.."{[["..line[1].."]],\""..line[2].."\",\""..line[3].."\"},\n"
    end
    text = text.."}"

    return text
end

local displayFunction = [[function(self,term)
    for i=1,#self.palette do
        term.setPaletteColor(2^(i-1),self.palette[i][1],self.palette[i][2],self.palette[i][3])
    end
    for i=1,self.sy do
        term.setCursorPos(1+self.px,i+self.py)
        term.blit(table.unpack(self.lines[i]))
    end
    return self
end]]

local function serizalizeRender(render,referenceDisplay)
    local serialisedPalette = textutils.serialize( render.palette , {compact=true})
    local serialisedLines = serializeLines( render.lines )

    local string = "{\n"
    .."palette="..serialisedPalette..",\n"
    .."sx="..render.sx..",\n"
    .."sy="..render.sy..",\n"
    .."px="..render.px..",\n"
    .."py="..render.py..",\n"
    .."lines="..serialisedLines..",\n"
    .."display="

    if (referenceDisplay==true)then
        string = string.."display"
    else
        string = string..displayFunction
    end

    string = string.."\n}"
    
    return string
end

-- 
PreCompiler.renderToLuaFile = function (content,filePath,contentType)
    contentType = contentType and contentType or "singleRender"

    local file = fs.open(filePath,"w")

    if (contentType=="sequence") then
        file.write("-- Pre compiled render file from ComBox\n")
        file.write("local display="..displayFunction)
        file.write("\nreturn{\n")
        for _,render in ipairs(content) do
            file.write( serizalizeRender(render,true) )
            file.write(",\n")
        end
        file.write("}")
    elseif (contentType=="album") then
        file.write("-- Pre compiled render file from ComBox\n")
        file.write("local display="..displayFunction)
        file.write("\nreturn{\n")
        for key,render in pairs(content) do
            file.write(key.."=")
            file.write( serizalizeRender(render,true) )
            file.write(",\n")
        end
        file.write("}")
    else
        file.write("-- Pre compiled render file from ComBox\nreturn")
        file.write(serizalizeRender(content))
    end

    file.close()
end

-- 
PreCompiler.renderToBinFile = function (content,filePath,contentType)
    contentType = contentType and contentType or "single"
    -- TODO
end

-- 
PreCompiler.getRenderFromFile = function (filePath)
    if ( findExtension(filePath) == "lua" ) then
        return require(filePath)
    else
        
        -- TODO : read file
        
    end
end

return PreCompiler