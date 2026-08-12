--[[

    Used to open and parse image files formats into ImageHandlers
    Supported formats :
        qoi

    MediaParser: {
        parsers: [ <format name>={
                        decode: function,
                        encode: function
                        }
                    ]          //
        parse:      function,
        open:       function,
        convert:    function,
        write:      function
    }

]]

if not import then error("use import to use this file not require") end

local ImageHandler = import "./image.lua"
local Color = import "./color.lua"
local png = import "./outsideLibs/png.lua"
local qoi = import "./outsideLibs/qoi.lua"

local MediaParser = {
    type='mediaParser',
    -- all supported image type/format and their corresponding decoder/encoder
    parsers = {
        qoi={
            decode=function(path)
                local fp = fs.open(shell.resolve(path),"r")
                return qoi.decode(fp.readAll())
            end
        },
        png={
            decode=function(path)
                local image = png(shell.dir().."/"..path)
                local pixels = {}
                for i=1,image.height do
                    for j=1,image.width do
                        local px = image.pixels[i][j]
                        pixels[(i-1)*image.width+j] = Color(px.R,px.G,px.B,px.A)
                    end
                end
                return pixels,{width=image.width,height=image.height}
            end
        }
    }
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

--[[
	Creates a new ImageHandler from the image data given,
    using the type/format given.

	parse(
        self:     MediaParser,
		data:     number,     // raw image data
        type:     String,     // type (format) of the data 
	) -> ImageHandler
]]
function MediaParser:parse(path,type)
    local pixels,desc = {},{}
    if self.parsers[type] then
        pixels,desc = self.parsers[type].decode(path)
    end
    local imageData = {}
    local timeYield = os.clock()
    for i=1,#pixels do
        if (os.clock() - timeYield > 5) then
            sleep()
            timeYield = os.clock()
        end
        local p = pixels[i]
        imageData[i] = Color:new(p[1]/255,p[2]/255,p[3]/255,p[4]/255)
    end
    return ImageHandler:new(desc.width,desc.height,nil,imageData)
end

--[[
    Opens the chosen file then
	creates a new ImageHandler from the image data given,
    using the type/format of the file.

	open(
        self:     MediaParser,
		path:     String,     // path of the file to open
	) -> ImageHandler
]]
function MediaParser:open(path)
    return self:parse(path,findExtension(path))
end

--[[
function MediaParser:convert(image)

end


function MediaParser:write(data,path)

end
]]

return MediaParser