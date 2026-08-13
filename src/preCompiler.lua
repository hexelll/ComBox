local PreCompiler = {}

local BIT = import "utils/numberlua.lua".bit
local Color = import "color.lua"

local function round(x)
    return math.floor(x+0.4999)
end


local hexTable = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"}
-- reverse of hexTable
local hexTableI = {
    ["0"] = 0,
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["a"] = 10,
    ["b"] = 11,
    ["c"] = 12,
    ["d"] = 13,
    ["e"] = 14,
    ["f"] = 15
}

-- internal util
local function findExtension(path)
    local i = path:find("%.")
    while i do
        path = path:sub(i+1,#path)
        i = path:find("%.")
    end
    return path
end

local function intToBytes(integer,size)
    local bytes = {}
    for i=0,size-1 do
        local val = BIT.rshift( BIT.band(integer, BIT.lshift(255, 8*i) ), 8*i )
        bytes[size-i] = string.char(val)
        --write(hexTable2[((val - val%16)/16)+1])
        --write(hexTable2[(val%16)+1])
    end
    return table.concat(bytes)
end
local function fileToInt(file,size)
    local integer = 0
    for i=1,size do
        integer = BIT.bor(integer, BIT.lshift(file.read(), 8*(size-i)))
    end
    return integer
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

local function serializeRenderToLua(render,referenceDisplay)
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

local function serializeRenderToBin(render)
    local string = ""
    
    local palette = {}
    for i,color in pairs(render.palette) do
        palette[(i-1)*3+1] = string.char(round(color[1] * 255))
        palette[(i-1)*3+2] = string.char(round(color[2] * 255))
        palette[(i-1)*3+3] = string.char(round(color[3] * 255))
    end
    local paletteString = table.concat(palette)

    local linesString = ""
    for _,line in pairs(render.lines) do
        local colors = {}
        for i=1,line[2]:len() do
            local textColor = hexTableI[string.sub(line[2],i,i)]
            local backColor = hexTableI[string.sub(line[3],i,i)]
            colors[i] = string.char( textColor*16 + backColor )
        end
        local colorsString = table.concat(colors)
        local lineString = table.concat({line[1],colorsString,"\n"})
        linesString = table.concat({linesString,lineString})
    end
    
    string = table.concat({string.char(#render.palette),paletteString,"\n",linesString})
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
        for _,render in pairs(content) do
            file.write( serializeRenderToLua(render,true) )
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
            file.write( serializeRenderToLua(render,true) )
            file.write(",\n")
            sleep()
        end
        file.write("}")
    else
        file.write("-- Pre compiled render file from ComBox\nreturn")
        file.write(serializeRenderToLua(content))
    end

    file.close()
end

-- 
PreCompiler.renderToBinFile = function (content,filePath,contentType)
    fs.delete(filePath)
    local file = fs.open(filePath,"wb")
    
    if (contentType=="sequence") then  
        file.write("ComBox pre compiled render file\n")
        file.write("SEQUENCE\n")
        file.write(intToBytes(content[1].sx,4))
        file.write(intToBytes(content[1].sy,4))
        file.write("\n")
        file.write(intToBytes(content[1].px,4))
        file.write(intToBytes(content[1].py,4))
        file.write("\n")
        file.write(intToBytes(#content,4))
        file.write("\n")

        for _,render in pairs(content) do
            file.write(serializeRenderToBin(render))
            sleep()
        end
    elseif (contentType=="album") then
        file.write("ComBox pre compiled render file\n")
        file.write("ALBUM\n")
        
    else
        file.write("ComBox pre compiled render file\n")
        file.write("SINGLE\n")
        file.write(intToBytes(content.sx,4))
        file.write(intToBytes(content.sy,4))
        file.write("\n")
        file.write(intToBytes(content.px,4))
        file.write(intToBytes(content.py,4))
        file.write("\n")
        file.write(serializeRenderToBin(content))
    end

    file.close()
end

local function readBinRender(f,sx,sy)
    -- palette
    local paletteSize = f.read()
    local palette = {}
    for i=1,paletteSize do
        palette[i] = Color( f.read()/255, f.read()/255, f.read()/255 )
    end
    f.read()-- new line caracter

    -- render content
    local lines = {}
    for y=1,sy do
        local chars = {}
        for x=1,sx do
            chars[x] = string.char(f.read())
        end
        
        local textColors = {}
        local backColors = {}
        for x=1,sx do
            local val = f.read()
            textColors[x] = hexTable[((val - val%16)/16)+1]
            backColors[x] = hexTable[(val%16)+1]
        end
        f.read()-- new line caracter

        lines[y] = { table.concat(chars), table.concat(textColors), table.concat(backColors) }
    end
    return {lines,palette}
end

-- 
PreCompiler.getRenderFromFile = function (filePath)
    if ( findExtension(filePath) == "lua" ) then
        return require(filePath)
    else
        local f = fs.open(filePath,"rb")

        -- ignore first line comment
        local char = f.read()
        while ( char ~= 10) do -- read until first new line
            char = f.read()
        end

        -- file attributes
        local typeBytes = {}
        local i = 1
        char = string.char(f.read())
        while ( char ~= "\n") do -- read until first new line
            typeBytes[i] = char
            i = i + 1
            char = string.char(f.read())
        end
        local type = table.concat(typeBytes)

        -- render attributes
        local sx = fileToInt(f,4)
        local sy = fileToInt(f,4)
        f.read()-- new line caracter
        local px = fileToInt(f,4)
        local py = fileToInt(f,4)
        f.read()-- new line caracter

        if (type == "SINGLE")then
            local render = readBinRender(f,sx,sy)

            return {
                lines=render[1],
                palette=render[2],
                sx=sx,sy=sy,
                px=px,py=py,
                display=function(self,term)
                    for i=1,#self.palette do
                        term.setPaletteColor(2^(i-1),self.palette[i][1],self.palette[i][2],self.palette[i][3])
                    end
                    for i=1,self.sy do
                        term.setCursorPos(1+self.px,i+self.py)
                        term.blit(table.unpack(self.lines[i]))
                    end
                    return self
                end
            }
        
        elseif (type == "SEQUENCE") then
            local nbRenders = fileToInt(f,4)
            f.read()-- new line caracter
            
            local renders = {}
            for i=1,nbRenders do
            
                local render = readBinRender(f,sx,sy)

                renders[i] = {
                        lines=render[1],
                        palette=render[2],
                        sx=sx,sy=sy,
                        px=px,py=py,
                        display=function(self,term)
                            for i=1,#self.palette do
                                term.setPaletteColor(2^(i-1),self.palette[i][1],self.palette[i][2],self.palette[i][3])
                            end
                            for i=1,self.sy do
                                term.setCursorPos(1+self.px,i+self.py)
                                term.blit(table.unpack(self.lines[i]))
                            end
                            return self
                        end
                    }
            end
            return renders
        
        else -- type == "ALBUM"
            
        end
    end
end

return PreCompiler