local TimeUtil = {}

--- Returns the total elapsed time in seconds since the engine started.
---@return number
function TimeUtil.getTicks()
    return love.timer.getTime()
end

return TimeUtil
