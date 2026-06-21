local InputBackend = {}

---Queries if a specific hardware keyboard key is physically depressed
---@param key string
---@return boolean
function InputBackend.isKeyDown(key)
    return love.keyboard.isDown(key)
end

---Queries the current cursor coordinates on the physical viewport
---@return number mx, number my
function InputBackend.getMousePosition()
    return love.mouse.getPosition()
end

return InputBackend
