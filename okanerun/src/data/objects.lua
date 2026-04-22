local Objects = {}

local files = love.filesystem.getDirectoryItems("okanerun/src/data/objectData")
for _, file in ipairs(files) do
    if file:match("%.lua$") then
        local name = file:gsub("%.lua$", "")
        Objects[name] = require("okanerun.src.data.objectData." .. name)
    end
end

return Objects
