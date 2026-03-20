require("love.image")
require("love.sound")
require("love.timer")

local loader_channel = love.thread.getChannel("fore_loader")
local response_channel = love.thread.getChannel("fore_response")

while true do
    local task = loader_channel:pop()
    
    if task then
        if task.cmd == "load_image" then
            local ok, data = pcall(love.image.newImageData, task.path)
            if ok then
                response_channel:push({
                    type = "image", 
                    name = task.name, 
                    data = data, 
                    imgtype = task.imgtype
                })
            else
                -- Push an error so the framework doesn't wait forever
                response_channel:push({type = "error", name = task.name})
            end
        elseif task.cmd == "load_audio" then
            local ok, data = pcall(love.sound.newSoundData, task.path)
            if ok then
                response_channel:push({type = "audio", name = task.name, data = data, category = task.category})
            else
                response_channel:push({type = "error", name = task.name})
            end
        elseif task.cmd == "quit" then 
            break 
        end
    end
    
    if love.timer then
        love.timer.sleep(0.001)
    end
end