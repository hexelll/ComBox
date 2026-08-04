local Pipeline = import '../Pipeline.lua'

return Pipeline:new()
    :entry()
    :after("entry","resize")