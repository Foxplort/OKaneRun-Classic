---@class Input
---@field actions table<string, table>
---@field state table<string, boolean>
---@field prev table<string, boolean>
---@field axes table<string, number>
---@field joysticks table
---@field lastInputMethod "keyboard"|"gamepad"|"touch"
---@field deadzone number
---@field touches table<number, table>
---@field gestures table
local Input = {}
Input.__index = Input

---Create new input handler
---@param fore fore Engine instance
---@param deadzone number? Analog deadzone (default 0.4)
---@return Input
function Input.init(fore, deadzone)
    local self = setmetatable({
        actions = {},
        state = {},
        prev = {},
        axes = {},
        joysticks = {},
        deadzone = deadzone or 0.4,
        fore = fore,
        lastInputMethod = "keyboard",
        touches = {},
        gestures = {
            swipes = {},
            taps = {}
        }
    }, Input)

    self.backend = require("fore.backend." .. fore.backend .. ".input")
    
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
        editor = {
            keys = { "f8" }
        }
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
function Input:update(dt)
    self.prev = self.state
    self.state = {}
    self.axes = {}

    for action, bind in pairs(self.actions) do
        local down = false
        local axisValue = 0

        -- Keyboard
        if bind.keys then
            for _, key in ipairs(bind.keys) do
                if self.backend.isKeyDown(key) then
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

        -- Gestures (Swipes map to actions)
        local useGestures = true
        local mcVisible = self.fore and self.fore.mobileControls and self.fore.mobileControls.visible
        if mcVisible then
            useGestures = false
        end

        if useGestures and not down then
            if action == "up" and self.gestures.swipes.up then down = true
            elseif action == "down" and self.gestures.swipes.down then down = true
            elseif action == "left" and self.gestures.swipes.left then down = true
            elseif action == "right" and self.gestures.swipes.right then down = true
            elseif action == "accept" and self.gestures.taps.any and not self.gestures.taps.double then down = true
            --elseif action == "cancel" and self.gestures.taps.double then down = true
            end
        end

        self.state[action] = down
        self.axes[action] = axisValue
    end

    -- Clear one-frame gestures
    self.gestures.swipes = {}
    self.gestures.taps = {}
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
    self.touches = {}
    self.gestures = { swipes = {}, taps = {} }
end

---Get the last input method used
---@return "keyboard"|"gamepad"|"touch"
function Input:getMethod()
    return self.lastInputMethod
end

---Set the last input method used
---@param method "keyboard"|"gamepad"|"touch"
function Input:setMethod(method)
    self.lastInputMethod = method
end

---Check if there's at least one active touch on the screen
---@return boolean
function Input:isTouching()
    for _ in pairs(self.touches) do return true end
    return false
end

-- ###################### --
-- ### TOUCH HANDLERS ### --
-- ###################### --

function Input:touchpressed(id, x, y)
    self.touches[id] = {
        startX = x,
        startY = y,
        time = self.fore.time.getTicks()
    }
    self:setMethod("touch")
end

function Input:touchreleased(id, x, y)
    local t = self.touches[id]
    if not t then return end

    local dx = x - t.startX
    local dy = y - t.startY
    local dist = math.sqrt(dx*dx + dy*dy)
    local duration = self.fore.time.getTicks() - t.time

    if dist > 40 then
        -- Swipe
        local absX = math.abs(dx)
        local absY = math.abs(dy)
        if absX > absY then
            if dx > 0 then self.gestures.swipes.right = true
            else self.gestures.swipes.left = true end
        else
            if dy > 0 then self.gestures.swipes.down = true
            else self.gestures.swipes.up = true end
        end
    elseif duration < 0.3 then
        -- Tap
        self.gestures.taps.any = true
        self.gestures.taps.x = x
        self.gestures.taps.y = y
        
        local now = self.fore.time.getTicks()
        if self.lastTapTime and now - self.lastTapTime < 0.3 then
            self.gestures.taps.double = true
            self.lastTapTime = nil
        else
            self.lastTapTime = now
        end
    end

    self.touches[id] = nil
end

return Input