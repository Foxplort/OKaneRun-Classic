local MiscUtil = {}
local fore = nil

function MiscUtil.init(foreRef)
    fore = foreRef
    return MiscUtil
end

function MiscUtil.platform()
    local LOVE_OS = love.system.getOS()
    if LOVE_OS == "Android" then return "android" end
    if LOVE_OS == "iOS" then return "ios" end
    if LOVE_OS == "Windows" then return "windows" end
    if LOVE_OS == "Linux" then return "linux" end
    if LOVE_OS == "OS X" then return "macos" end
    return "unknown"
end

function MiscUtil.isMobile()
    return fore.data.OS == "android" or fore.data.OS == "ios"
end

return MiscUtil
