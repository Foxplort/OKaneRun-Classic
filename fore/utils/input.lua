---@class Input
---@field actions table<string, table>
---@field state table<string, boolean>
---@field prev table<string, boolean>
---@field axes table<string, number>
---@field joysticks table
---@field lastInputMethod "keyboard"|"gamepad"
---@field deadzone number
local Input = {}
Input.__index = Input

---Create new input handler
---@param deadzone number? Analog deadzone (default 0.4)
---@return Input
function Input.init(deadzone)
    local self = setmetatable({
        actions = {},
        state = {},
        prev = {},
        axes = {},
        joysticks = {},
        deadzone = deadzone or 0.4,
        lastInputMethod = "keyboard",
    }, Input)
    
    -- Register core engine actions
    self:registerAll({
        debug = {
            keys = { "k", "f3" },
            buttons = { "back" }
        },
        debugRestart = {
            keys = { "f6" }
        },
        fullscreen = {
            keys = { "f11" }
        },
        volumeUp = {
            keys = { "=" }
        },
        volumeDown = {
            keys = { "-" }
        },
    })
    
    return self
end

---Register an action
---@param name string
---@param bind table
function Input:register(name, bind)
    self.actions[name] = bind
end

---Register multiple actions
---@param actions table<string, table>
function Input:registerAll(actions)
    for name, bind in pairs(actions) do
        self:register(name, bind)
    end
end

---Update input states
function Input:update()
    self.prev = self.state
    self.state = {}
    self.axes = {}

    for action, bind in pairs(self.actions) do
        local down = false
        local axisValue = 0

        -- Keyboard
        if bind.keys then
            for _, key in ipairs(bind.keys) do
                if love.keyboard.isDown(key) then
                    down = true
                    axisValue = 1
                    break
                end
            end
        end

        -- Gamepad buttons
        if not down and bind.buttons then
            for _, pad in ipairs(self.joysticks) do
                for _, button in ipairs(bind.buttons) do
                    if pad:isGamepadDown(button) then
                        down = true
                        axisValue = 1
                        break
                    end
                end
                if down then break end
            end
        end

        -- Gamepad axes
        if bind.axes then
            for _, pad in ipairs(self.joysticks) do
                for _, axis in ipairs(bind.axes) do
                    local value = pad:getGamepadAxis(axis.axis)
                    if axis.dir < 0 and value < -self.deadzone then
                        down = true
                        axisValue = math.max(axisValue, -value)
                    elseif axis.dir > 0 and value > self.deadzone then
                        down = true
                        axisValue = math.max(axisValue, value)
                    end
                end
            end
        end

        self.state[action] = down
        self.axes[action] = axisValue
    end
end

---Check if action is currently down
---@param action string
---@return boolean
function Input:down(action)
    return self.state[action] or false
end

---Check if action was just pressed this frame
---@param action string
---@return boolean
function Input:pressed(action)
    return self.state[action] and not self.prev[action]
end

---Check if action was just released this frame
---@param action string
---@return boolean
function Input:released(action)
    return not self.state[action] and self.prev[action]
end

---Get analog value for action (0-1)
---@param action string
---@return number
function Input:axis(action)
    return self.axes[action] or 0
end

---Add joystick
---@param joystick Joystick
function Input:addJoystick(joystick)
    table.insert(self.joysticks, joystick)
end

---Remove joystick
---@param joystick Joystick
function Input:removeJoystick(joystick)
    for i, j in ipairs(self.joysticks) do
        if j == joystick then
            table.remove(self.joysticks, i)
            break
        end
    end
end

---Clear all input states
function Input:clear()
    self.state = {}
    self.prev = {}
    self.axes = {}
end

---Get the last input method used
---@return "keyboard"|"gamepad"
function Input:getMethod()
    return self.lastInputMethod
end

---Set the last input method used
---@param method "keyboard"|"gamepad"
function Input:setMethod(method)
    self.lastInputMethod = method
end

return Input