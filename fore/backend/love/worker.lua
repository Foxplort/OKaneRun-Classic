local Worker = {}

local loader_channel = nil
local response_channel = nil
local thread = nil

--- Spawns the background worker thread and hooks up channels
function Worker.init(fore)
    loader_channel = love.thread.getChannel("fore_loader")
    response_channel = love.thread.getChannel("fore_response")

    -- Spawn the thread file
    thread = love.thread.newThread("fore/backend/love/unique/loaderThread.lua")
    thread:start()
end

--- Pushes a loading command to the background thread
---@param task table { cmd: string, name: string, path: string, ... }
function Worker.push(task)
    if loader_channel then
        loader_channel:push(task)
    end
end

--- Pops a completed asset response message if one is available
---@return table|nil
function Worker.pop()
    if response_channel then
        return response_channel:pop()
    end
    return nil
end

return Worker
