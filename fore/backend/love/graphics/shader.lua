local ShaderUtil = {
    _stack = {}
}

ShaderUtil.__index = ShaderUtil

--- Loads a shader
---@param path_or_vs string Path to single shader or vertex shader
---@param optional_fs string|nil Path to fragment shader (optional)
---@return Shader object
function ShaderUtil.new(path_or_vs, optional_fs)
    local instance = setmetatable({}, ShaderUtil)

    if optional_fs then
        instance.shader = love.graphics.newShader(path_or_vs, optional_fs)
    else
        instance.shader = love.graphics.newShader(path_or_vs)
    end

    return instance
end

--- Sends a value to the shader
---@param name string Name of the variable in the shader
---@param value any Value to send
---@param uniform_type string|nil Type of uniform (used for Raylib)
function ShaderUtil:send(name, value, uniform_type)
    -- Note: uniform_type is ignored in LOVE
    self.shader:send(name, value)
end

--- Pushes shader onto the stack and activates it
function ShaderUtil:push()
    table.insert(ShaderUtil._stack, self.shader)
    love.graphics.setShader(self.shader)
end

--- Pops the top active shader off the stack and restores the previous one
function ShaderUtil.pop()
    if #ShaderUtil._stack == 0 then
        error("Attempted to pop a shader from an empty stack")
    end
    
    -- Remove the top shader
    table.remove(ShaderUtil._stack)
    
    -- Get the previous shader (if any)
    local previous = ShaderUtil._stack[#ShaderUtil._stack]
    
    if previous then
        love.graphics.setShader(previous)
    else
        love.graphics.setShader()
    end
end

return ShaderUtil
