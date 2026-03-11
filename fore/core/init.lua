-- FÖRE Engine
-- Copyright (c) 2026 foxplort
-- This Source Code Form is subject to the terms of the Mozilla Public License 2.0.
-- https://mozilla.org/MPL/2.0/

local Fore = {
    version = '0.0.0',
}

Fore.Fx = {
    r = require("fore.utils.renderer"),
    s = require("fore.utils.soundManager"),
    i = require("fore.utils.input").new(),
    m = require("fore.utils.math"),
    dq = require("fore.utils.drawqueue"),
    debug = require("fore.systems.debug"),
}

Fore.Fx.SceneManager = require("fore.core.sceneManager")

function Fore.init(gameConfig)
    Fore.conf = require("fore.core.config").new(gameConfig)
    
    Fore.SceneManager = Fore.Fx.SceneManager.new(Fore.conf.minDT)
    
    love.window.setMode(
        Fore.conf.baseWidth * (Fore.conf.windowScale or 1),
        Fore.conf.baseHeight * (Fore.conf.windowScale or 1),
        Fore.conf.windowFlags or {}
    )
    
    if Fore.conf.title then
        love.window.setTitle(Fore.conf.title)
    end
    
    if Fore.conf.icon then
        love.window.setIcon(love.image.newImageData(Fore.conf.icon))
    end
    
    return Fore
end

return Fore
