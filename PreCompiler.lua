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

local function serializeRender(render,referenceDisplay)
    local serialisedPalette = textutils.serialize( render.palette , {compact=true})
    local serialisedLines = serializeLines( render.lines )

    local display = (referenceDisplay==true) and "display" or displayFunction

    local string = table.concat({
        "{\npalette=",serialisedPalette,
        ",\nsx=",render.sx,
        ",\nsy=",render.sy,
        ",\npx=",render.px,
        ",\npy=",render.py,
        ",lines=",serialisedLines,
        ",\ndisplay=",display,
        "\n}"
    })
    
    return string
end

-- 
PreCompiler.renderToLuaFile = function (content,filePath,contentType)
    fs.delete(filePath)
    local file = fs.open(filePath,"w")

    if (contentType=="sequence") then
        file.write("-- Pre compiled render file from ComBox\n")
        file.write("local display=")
        file.write(displayFunction)
        file.write("\nreturn{\n")
        for _,render in ipairs(content) do
            file.write( serializeRender(render,true) )
            file.write(",\n")
            sleep()
        end
        file.write("}")
    elseif (contentType=="album") then
        file.write("-- Pre compiled render file from ComBox\n")
        file.write("local display=")
        file.write(displayFunction)
        file.write("\nreturn{\n")
        for key,render in pairs(content) do
            file.write(key)
            file.write("=")
            file.write( serializeRender(render,true) )
            file.write(",\n")
            sleep()
        end
        file.write("}")
    else
        file.write("-- Pre compiled render file from ComBox\nreturn")
        file.write(serializeRender(content))
    end

    file.close()
end

-- 
PreCompiler.renderToBinFile = function (content,filePath,contentType)
    fs.delete(filePath)
    local file = fs.open(filePath,"wb")
    
    if (contentType=="sequence") then  
        print() 
    elseif (contentType=="album") then
        print()
    else
        file.write(40)
    end

    file.close()
end

-- 
PreCompiler.getRenderFromFile = function (filePath)
    if ( findExtension(filePath) == "lua" ) then
        return require(filePath)
    else
        
        print()
        -- TODO : read file
    end
end

return PreCompiler