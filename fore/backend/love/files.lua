local Files = {}

local activeMounts = {}

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

---Create a directory inside the sandbox window workspace
---@param path string
function Files.createDirectory(path)
    return love.filesystem.createDirectory(path)
end

---Returns an array containing all files and subdirectories in a directory path
---@param path string
---@return table
function Files.listFiles(path)
    -- Wraps love.filesystem.getDirectoryItems directly
    return love.filesystem.getDirectoryItems(path)
end

---Gets the absolute directory path where save states are kept on the OS
---@return string
function Files.getHomeDirectoryRoots()
    return love.filesystem.getSaveDirectory()
end

---Remove a file
---@param path string
function Files.remove(path)
    return love.filesystem.remove(path)
end

---Mounts a directory or compressed zip archive path to a virtual folder mount point
---@param path string The path to the file/archive inside your layout folder
---@param mountPoint string The virtual engine folder path to map it to
---@return boolean
function Files.mountArchive(path, mountPoint)
    -- If it's already mounted, skip
    if activeMounts[mountPoint] then return true end

    local fileData = love.filesystem.newFileData(path)
    if fileData then
        local success = love.filesystem.mount(fileData, mountPoint)
        if success then
            activeMounts[mountPoint] = fileData
            return true
        end
    end
    return false
end

---Safely tears down and unmounts a virtual tracking path
---@param mountPoint string
---@return boolean
function Files.unmountArchive(mountPoint)
    local fileData = activeMounts[mountPoint]
    if fileData then
        local success = love.filesystem.unmount(fileData)
        if success then
            activeMounts[mountPoint] = nil
            return true
        end
    end
    return false
end

return Files