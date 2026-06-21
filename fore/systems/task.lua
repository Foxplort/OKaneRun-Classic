local TaskSystem = {}
local activeTasks = {}

---Registers a function to execute after a non-blocking time delay
---@param time number Duration in seconds
---@param callback function The function to run
function TaskSystem.delay(time, callback)
    table.insert(activeTasks, {
        timer = 0,
        target = time,
        run = callback
    })
end

---Updates all pending tasks. CALLED AUTOMATICALLY, DO NOT CALL YOURSELF
---@param dt number
function TaskSystem.update(dt)
    for i = #activeTasks, 1, -1 do
        local task = activeTasks[i]
        task.timer = task.timer + dt
        if task.timer >= task.target then
            task.run()
            table.remove(activeTasks, i)
        end
    end
end

return TaskSystem