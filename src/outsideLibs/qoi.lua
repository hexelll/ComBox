local M = import("./numberlua.lua")
local bit = M.bit

local qoi = {
    headerSize = 14,
    opIndex = 0x00,
    opDiff = 0x40,
    opLuma = 0x80,
    opRun = 0xc0,
    opRgb = 0xfe,
    opRgba = 0xff,
    mask2 = 0xc0,
    padding = "\0\0\0\0\0\0\0\1"
}

function qoi.write32(bytes,p,v)
    bytes[p.p] = bit.rshift(bit.band(0xff000000,v),24)
    p.p = p.p+1
    bytes[p.p] = bit.rshift(bit.band(0x00ff0000,v),16)
    p.p = p.p+1
    bytes[p.p] = bit.rshift(bit.band(0x0000ff00,v),8)
    p.p = p.p+1
    bytes[p.p] = bit.band(0x000000ff,v)
    p.p = p.p+1
end

function qoi.read32(bytes,p)
    local a = bytes[p.p]
    p.p=p.p+1
    local b = bytes[p.p]
    p.p=p.p+1
    local c = bytes[p.p]
    p.p=p.p+1
    local d = bytes[p.p]
    p.p=p.p+1
    return bit.bor(
        bit.bor(
            bit.lshift(a,24),
            bit.lshift(b,16)
        ),
        bit.bor(
            bit.lshift(c,8),
            d
        )
    )
end

function qoi.colorHash(c)
    return c.r*3+c.g*5+c.b*7+c.a*11
end

function qoi.decode(data)
    local pixels = {}
    local bytes = {}
    local size = #data
    local p,run = {p=1},0

    local desc = {}

    if not data then 
        error("missing data")
    end

    for i=1,#data do
        b = data:byte(i)
        bytes[#bytes+1] = b
    end

    local function getByte()
        local b = bytes[p.p]
        p.p=p.p+1
        return b
    end

    local headerMagic = data:sub(p.p,p.p+3)
    p.p = p.p+4
    desc.width = qoi.read32(bytes,p)
    desc.height = qoi.read32(bytes,p)
    desc.channels = getByte()
    desc.colorspace = getByte()
    if desc.width == 0 or 
    desc.height == 0 or 
    desc.channels < 3 or 
    desc.channels > 4 or
    desc.colorspace > 1 or
    headerMagic ~= "qoif" then
        error("malformed file")
    end
    local pixelsLen = desc.width*desc.height

    local index = {
		-- 64 RGBA pixels.
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
		0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	}
    local px = {
        r=0,
        g=0,
        b=0,
        a=255
    }
    local chunksLen = #data - #qoi.padding
    local timeYield = os.clock()
    for pxPos=1,pixelsLen do
        if (os.clock() - timeYield > 5) then
            sleep()
            timeYield = os.clock()
        end
        if run > 0 then
            run=run-1
        elseif p.p < chunksLen then
            local b1 = getByte()
            if b1 == qoi.opRgb then
                px.r = getByte()
                px.g = getByte()
                px.b = getByte()
            elseif b1 == qoi.opRgba then
                px.r = getByte()
                px.g = getByte()
                px.b = getByte()
                px.a = getByte()
            elseif bit.band(b1,qoi.mask2) == qoi.opIndex then
                local hash4 = bit.lshift(b1,2)
                px.r = index[hash4+1]
                px.g = index[hash4+2]
                px.b = index[hash4+3]
                px.a = index[hash4+4]
            elseif bit.band(b1,qoi.mask2) == qoi.opDiff then
                b1 = b1 - 64
				px.r = px.r + bit.rshift(bit.band(b1, 48--[[00110000]]), 4) - 2
				px.g = px.g + bit.rshift(bit.band(b1, 12--[[00001100]]), 2) - 2
				px.b = px.b +        bit.band(b1, 3 --[[00000011]])     - 2
            elseif bit.band(b1,qoi.mask2) == qoi.opLuma then
                local b2 = getByte()
                local diffG = b1 + (-(128--[[10000000]]) - 32)
				px.g = px.g + diffG
				px.r = px.r + diffG + bit.rshift(bit.band(b2, 240--[[11110000]]), 4) - 8
				px.b = px.b + diffG +        bit.band(b2, 15 --[[00001111]])     - 8
            elseif bit.band(b1,qoi.mask2) == qoi.opRun then
                run = bit.band(b1,0x3f)
            end
            local hash = bit.lshift(bit.band(qoi.colorHash(px),63),2)
            
             if px.r < 0 then
                px.r = px.r + 256
            end
            if px.g < 0 then
                px.g = px.g + 256
            end
            if px.b < 0 then
                px.b = px.b + 256
            end

            index[hash+1] = px.r
            index[hash+2] = px.g
            index[hash+3] = px.b
            index[hash+4] = px.a
           
        end
        pixels[pxPos] = {px.r,px.g,px.b,px.a}
    end

    return pixels,desc
end

return qoi

--[[
local fh = fs.open(shell.resolve("rusure.qoi"),"r")

local pixels,desc = qoi.decode(fh.readAll())

local renderer = require "renderer"
local mon = peripheral.find("monitor")
mon.setTextScale(0.5)
local r = renderer.new{term=mon}

for x=1,r.size.x do
    for y=1,r.size.y do
        local u,v = (x-1)/r.size.x,(y-1)/r.size.y
        local c = pixels[1+math.floor(u*desc.width+0.499)+(1+math.floor(v*desc.height+0.499))*desc.width]
        c = c and {c[1]/255,c[2]/255,c[3]/255} or {0,0,0}
        r:setPx({x=x,y=y},c)
    end
end

local lines = r:asLines()
r
:optimizeColors(40,0.1,16)
:floyddither(1)
:render(lines)
r:applyPalette()

fh.close()]]