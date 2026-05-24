--[[

    this is a combinator meant to achieve more perceived colors by combining text color and background color
    it works by searching for all combinations of background color,text color and character,
    it is rather slow and not meant for real-time use but quality of render

    CharCombinator: {
        name: string,
        new: function,
        onPaletteChange: function,
        onImageChange: function,
        findCombination: function
    }

]]


local CharCombinator = {name="CharCombinator"}

local hexTable = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"}
local charCoefs = {0 ,19/54 ,25/54 ,21/54 ,13/54 ,19/54 ,18/54 ,12/54 ,36/54 ,0 ,0 ,14/54 ,17/54 ,0 ,15/54 ,22/54 ,13/54 ,13/54 ,20/54 ,12/54 ,19/54 ,20/54 ,8/54 ,24/54 ,13/54 ,13/54 ,11/54 ,11/54 ,7/54 ,10/54 ,13/54 ,13/54 ,0 ,6/54 ,6/54 ,20/54 ,15/54 ,11/54 ,15/54 ,3/54 ,9/54 ,9/54 ,6/54 ,9/54 ,3/54 ,5/54 ,2/54 ,7/54 ,19/54 ,12/54 ,16/54 ,14/54 ,15/54 ,17/54 ,15/54 ,12/54 ,17/54 ,15/54 ,4/54 ,5/54 ,7/54 ,10/54 ,7/54 ,14/54 ,24/54 ,18/54 ,20/54 ,13/54 ,18/54 ,17/54 ,13/54 ,17/54 ,17/54 ,11/54 ,10/54 ,15/54 ,11/54 ,17/54 ,17/54 ,16/54 ,14/54 ,16/54 ,18/54 ,15/54 ,11/54 ,15/54 ,13/54 ,17/54 ,13/54 ,9/54 ,15/54 ,11/54 ,7/54 ,11/54 ,5/54 ,5/54 ,3/54 ,14/54 ,16/54 ,11/54 ,16/54 ,15/54 ,11/54 ,17/54 ,14/54 ,6/54 ,11/54 ,12/54 ,7/54 ,13/54 ,12/54 ,12/54 ,14/54 ,14/54 ,9/54 ,13/54 ,9/54 ,12/54 ,9/54 ,14/54 ,9/54 ,15/54 ,13/54 ,9/54 ,7/54 ,9/54 ,6/54 ,1/3 ,0 ,1/6 ,1/6 ,1/3 ,1/6 ,1/3 ,1/3 ,1/2 ,1/6 ,1/3 ,1/3 ,1/2 ,1/3 ,1/2 ,1/2 ,2/3 ,1/6 ,1/3 ,1/3 ,1/2 ,1/3 ,1/2 ,1/2 ,2/3 ,1/3 ,1/2 ,1/2 ,2/3 ,1/2 ,2/3 ,2/3 ,5/6 ,0 ,6/54 ,13/54 ,16/54 ,16/54 ,17/54 ,6/54 ,20/54 ,2/54 ,20/54 ,11/54 ,10/54 ,7/54 ,5/54 ,18/54 ,5/54 ,8/54 ,14/54 ,7/54 ,8/54 ,2/54 ,15/54 ,19/54 ,4/54 ,2/54 ,8/54 ,12/54 ,10/54 ,14/54 ,13/54 ,17/54 ,9/54 ,16/54 ,16/54 ,19/54 ,18/54 ,16/54 ,15/54 ,20/54 ,14/54 ,18/54 ,18/54 ,21/54 ,18/54 ,11/54 ,11/54 ,12/54 ,11/54 ,19/54 ,17/54 ,16/54 ,16/54 ,17/54 ,16/54 ,16/54 ,9/54 ,19/54 ,13/54 ,13/54 ,12/54 ,13/54 ,9/54 ,14/54 ,19/54 ,16/54 ,16/54 ,19/54 ,18/54 ,16/54 ,15/54 ,17/54 ,13/54 ,17/54 ,17/54 ,20/54 ,17/54 ,7/54 ,7/54 ,8/54 ,7/54 ,15/54 ,16/54 ,14/54 ,14/54 ,17/54 ,16/54 ,14/54 ,7/54 ,15/54 ,14/54 ,14/54 ,13/54 ,14/54 ,17/54 ,13/54 ,17/54}

local function round(x)
    return math.floor(x+0.4999)
end

--[[

    this function creates a new CharCombinator instance, 
    this should generaly only be done once per program

    function new(
        self: CharCombinator,
        args:{
            cacheSize: ?number | 100,
            nbSearched: ?number | 1,
            usedChars: ?[number] | [1..255]
        }
    ) -> CharCombinator

]]
function CharCombinator:new(args)
    args = args and args or {}
    local o = {}

    o.nbSearched = args.nbSearched and args.nbSearched or 1
    o.cacheSize = args.cacheSize and args.cacheSize or 100
    
    o.usedChars = args.usedChars and args.usedChars or {}
    if ( #o.usedChars == 0) then
        o.usedChars = {}
        for i=1,255 do
            o.usedChars[#o.usedChars+1] = i-1
        end
    end
    
    o.combinationTable = {}   

    o.usedCharsCoef = {}
    for _,charNum in ipairs(o.usedChars) do
        table.insert( o.usedCharsCoef , charCoefs[charNum+1] )
    end

    o.cache = {}

    setmetatable(o,{
        __index=function(_,k)
            return self[k]
        end
    })

    return o
end

--[[

    this function is called when the palette is different from last Renderer.render call

    onPaletteChange(
        self: CharCombinator,
        palette: [Color],
        renderer: Renderer
    ) -> void

]]
function CharCombinator:onPaletteChange(palette,renderer)

    print("char:")
    for i,col in ipairs(palette)do
        print(col)
    end

    local combinationTable = {}
    for textColNum=1,#palette do

        local colorT = palette[textColNum]
        combinationTable[textColNum] = {}

        for backColNum=1,#palette do

            local colorB = palette[backColNum]
            combinationTable[textColNum][backColNum] = {}

            local closeness = colorT:distance(colorB) 

            if (textColNum~=backColNum) then

                for i=1,#self.usedChars do

                        local coef = self.usedCharsCoef[i]
                        
                        if ( coef == 0.5 and backColNum < textColNum) then
                            combinationTable[textColNum][backColNum][i] = nil
                        else
                            local color = colorT:mix(colorB,coef)

                            combinationTable[textColNum][backColNum][i] = {color,closeness}
                        end
                end 
            else
                combinationTable[textColNum][backColNum] = nil
            end
        end 
    end
    self.combinationTable = combinationTable

    self.cache = {}
end

--[[

    this function is called by Renderer when the image is different from last Renderer.render call

    onImageChange(
        self: CharCombinator,
        image: ImageHandler,
        palette: [Color],
        renderer: Renderer
    ) -> void

]]
function CharCombinator:onImageChange(image,palette,renderer)

end

--[[

    this function is used in Renderer to turn image information into actual characters displayed on the monitor
    it returns an array of size 3 in this format : 
    [character to display, palette index in hex format for the text color, palette index in hex format for the background color]

    findCombination(
        self: CharCombinator,
        u: number, 
        v: number, 
        image: ImageHandler, 
        palette: [Color]
    ) -> [char, char, char]

]]
function CharCombinator:findCombination(u,v,image,palette)
    local searchedColor = image:getPx(u,v)

    -- cache 
    local index = searchedColor:toHash(self.cacheSize)
    local cacheResult = self.cache[index]
    if ( cacheResult ) then
        return cacheResult
    else    
        local lastt = os.clock()

        -- search in self.combinationTable for closest combination to searchedColor
        -- keeps a list of best candidates of size self.nbSearched
        local combinationTable = self.combinationTable
        local usedChars = self.usedChars
        local nbSearched = self.nbSearched

        local best = {}   -- sorted by dif ascending

        for textColNum = 1, #combinationTable do
            if (os.clock()-lastt) > 5 then
                sleep()
                lastt = os.clock()
            end
            local row = combinationTable[textColNum]

            for backColNum = 1, #palette do
                if (os.clock()-lastt) > 5 then
                    sleep()
                    lastt = os.clock()
                end
                local cell = row[backColNum]

                if cell then
                    for i = 1, #usedChars do
                        local charNum = usedChars[i]
                        local comb = cell[i]

                        if comb then
                            local color = comb[1]
                            local closeness = comb[2]

                            local dif = color:distance(searchedColor)

                            -- inline sorted insertion
                            local inserted = false
                            local len = #best

                            for j = 1, len do
                                if dif < best[j][4] then
                                    table.insert(best,j, {
                                        textColNum,
                                        backColNum,
                                        charNum,
                                        dif,
                                        closeness
                                    })
                                    inserted = true
                                    break
                                end
                            end

                            if not inserted then
                                best[len + 1] = {
                                    textColNum,
                                    backColNum,
                                    charNum,
                                    dif,
                                    closeness
                                }
                            end

                            if #best > nbSearched then
                                best[nbSearched + 1] = nil
                            end
                        end
                    end
                end
            end
        end

        -- select smallest closeness (= smoothest combination) among the list found previously
        local bestIdx = 1
        local bestClose = best[1][5]
        for i = 2, #best do
            local cclose = best[i][5]
            if cclose < bestClose then
                bestClose = cclose
                bestIdx = i
            end
        end
        local bestofbests = best[bestIdx]

        local combination = {string.char(bestofbests[3]),hexTable[bestofbests[2]],hexTable[bestofbests[1]]}

        if (os.clock()-lastt) > 5 then
            sleep()
            lastt = os.clock()
        end
        self.cache[index] = combination
        return combination
    end
end

return CharCombinator