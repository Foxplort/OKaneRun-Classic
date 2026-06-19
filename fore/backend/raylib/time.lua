local TimeUtil = {}

--- Returns the total elapsed time in seconds since the engine started.
---@return number
function TimeUtil.getTicks()
    return rl.getTime()
end

return TimeUtil
