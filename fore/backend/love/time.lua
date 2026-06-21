local TimeUtil = {}

--- Returns the total elapsed time in seconds since the engine started.
---@return number
function TimeUtil.getTicks()
    return love.timer.getTime()
end

---Stops the entire engine for a specified duration of time.
---@param time number Duration in seconds to wait
function TimeUtil.wait(time)
    love.timer.sleep(time)
end

---Returns the difference in time between the last and current frame.
---@return number
function TimeUtil.getDelta()
    return love.timer.getDelta()
end

---Returns the average frames per second (FPS)
---@return number
function TimeUtil.getFPS()
    return love.timer.getFPS()
end

return TimeUtil
