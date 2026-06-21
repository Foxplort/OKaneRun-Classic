local Files = {}

---Write inside the LÖVE sandbox folder
---@param filename string
---@param content string
function Files.write(filename, content)
    return love.filesystem.write(filename, content)
end

---Read from the LÖVE sandbox folder
---@param filename string
---@return string|nil
function Files.read(filename)
    if not love.filesystem.getInfo(filename) then return nil end
    local content, size = love.filesystem.read(filename)
    return content
end

---Existence check
---@param filename string
---@return boolean
function Files.exists(filename)
    return love.filesystem.getInfo(filename) ~= nil
end

return Files