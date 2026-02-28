local SoundManager = {}

-- ################# --
-- ### VARIABLES ### --
-- #################--

SoundManager.sounds = {}
SoundManager.tempSounds = {}
SoundManager.music = {}
SoundManager.currentMusic = nil

SoundManager.masterVolume = 1.0
SoundManager.categories = {
    music   = { volume = 0.7, concurrent = false },
    sfx     = { volume = 0.8, concurrent = true  },
    ui      = { volume = 0.9, concurrent = true  },
    ambient = { volume = 0.5, concurrent = true  },
    steps   = { volume = 0.6, concurrent = true  }
}

SoundManager.playingSounds = {}
SoundManager.playingMusic = {}

-- ####################### --
-- ### INNER FUNCTIONS ### --
-- ####################### --

local function calculateVolume(category, customVolume)
    local cat = SoundManager.categories[category] or SoundManager.categories.sfx
    local baseVol = (customVolume or cat.volume) * SoundManager.masterVolume
    return math.max(0, math.min(1, baseVol))
end

local function getCategorySettings(category)
    return SoundManager.categories[category] or SoundManager.categories.sfx
end

-- ###################### --
-- ### LOAD FUNCTIONS ### --
-- ###################### --

function SoundManager.loadSound(name, path, category)
    category = category or "sfx"
    local sound = {
        source = love.audio.newSource(path, "static"),
        category = category,
        name = name
    }
    SoundManager.sounds[name] = sound
    return sound
end

function SoundManager.loadMusic(name, path, category)
    category = category or "music"
    local music = {
        source = love.audio.newSource(path, "stream"),
        category = category,
        name = name
    }
    SoundManager.music[name] = music
    return music
end

-- ###################### --
-- ###  PLAY FUNCTIONS ### --
-- ###################### --

function SoundManager.play(name, options)
    options = options or {}
    local sound = SoundManager.sounds[name] or SoundManager.music[name]
    if not sound then print("Warning: Sound '" .. name .. "' not found!") return nil end
    
    local category = options.category or sound.category
    local catSettings = getCategorySettings(category)
    local isMusic = category == "music" or category == "ambient"
    
    if not catSettings.concurrent then
        if isMusic then SoundManager.stopMusic()
        else SoundManager.stopCategory(category) end
    end
    
    local source = options.loop and sound.source or sound.source:clone()
    if options.loop then source:setLooping(true) end
    
    source:setVolume(options.volume or calculateVolume(category))
    if options.pitch then source:setPitch(options.pitch) end
    if options.pan then source:setPan(options.pan) end
    source:play()
    
    local playingInfo = {
        source = source, category = category, name = name,
        loop = options.loop or false, timestamp = love.timer.getTime()
    }
    
    if isMusic then
        SoundManager.playingMusic[name] = playingInfo
        SoundManager.currentMusic = playingInfo
    else
        table.insert(SoundManager.playingSounds, playingInfo)
    end
    return playingInfo
end

function SoundManager.playAndForget(name, options)
    options = options or {}
    local sound = SoundManager.sounds[name] or SoundManager.music[name]
    if not sound then print("Error: Cannot play '" .. name .. "' - not loaded") return nil end
    
    local category = options.category or sound.category
    local isMusic = category == "music" or category == "ambient"
    local source = sound.source:clone()
    
    source:setVolume(options.volume or calculateVolume(category))
    if options.pitch then source:setPitch(options.pitch) end
    if options.pan then source:setPan(options.pan) end
    source:play()
    
    local tempSound = {
        source = source, name = name, category = category,
        timestamp = love.timer.getTime(),
        unloadWhenDone = options.unloadWhenDone ~= false,
        originalSound = sound, isMusic = isMusic
    }
    table.insert(SoundManager.tempSounds, tempSound)
    return tempSound
end

function SoundManager.playSFX(name, options)
    options = options or {}; options.category = "sfx"
    return SoundManager.play(name, options)
end

function SoundManager.playUI(name, options)
    options = options or {}; options.category = "ui"
    return SoundManager.play(name, options)
end

function SoundManager.playSteps(name, options)
    options = options or {}; options.category = "steps"
    return SoundManager.play(name, options)
end

function SoundManager.playMusic(name, options)
    options = options or {}; options.category = "music"; options.loop = true
    return SoundManager.play(name, options)
end

function SoundManager.playAmbient(name, options)
    options = options or {}; options.category = "ambient"; options.loop = true
    return SoundManager.play(name, options)
end

-- ###################### --
-- ### STOP FUNCTIONS ### --
-- ###################### --

function SoundManager.stop(name)
    for i = #SoundManager.playingSounds, 1, -1 do
        if SoundManager.playingSounds[i].name == name then
            SoundManager.playingSounds[i].source:stop()
            table.remove(SoundManager.playingSounds, i)
        end
    end
    if SoundManager.playingMusic[name] then
        SoundManager.playingMusic[name].source:stop()
        SoundManager.playingMusic[name] = nil
        SoundManager.currentMusic = nil
    end
end

function SoundManager.stopCategory(category)
    for i = #SoundManager.playingSounds, 1, -1 do
        if SoundManager.playingSounds[i].category == category then
            SoundManager.playingSounds[i].source:stop()
            table.remove(SoundManager.playingSounds, i)
        end
    end
    for name, music in pairs(SoundManager.playingMusic) do
        if music.category == category then
            music.source:stop()
            SoundManager.playingMusic[name] = nil
            SoundManager.currentMusic = nil
        end
    end
end

function SoundManager.stopMusic()
    for name, music in pairs(SoundManager.playingMusic) do music.source:stop() end
    SoundManager.playingMusic = {}
    SoundManager.currentMusic = nil
end

function SoundManager.stopAll()
    for i = #SoundManager.playingSounds, 1, -1 do SoundManager.playingSounds[i].source:stop() end
    SoundManager.playingSounds = {}
    SoundManager.stopMusic()
end

-- ###################### --
-- ### VOLUME CONTROL ### --
-- ###################### --

function SoundManager.setMasterVolume(volume)
    SoundManager.masterVolume = math.max(0, math.min(1, volume))
    SoundManager.updateAllVolumes()
end

function SoundManager.setCategoryVolume(category, volume)
    if SoundManager.categories[category] then
        SoundManager.categories[category].volume = math.max(0, math.min(1, volume))
        SoundManager.updateCategoryVolumes(category)
    end
end

function SoundManager.setMusicVolume(volume)  SoundManager.setCategoryVolume("music", volume) end
function SoundManager.setSFXVolume(volume)    SoundManager.setCategoryVolume("sfx", volume) end
function SoundManager.setUIVolume(volume)     SoundManager.setCategoryVolume("ui", volume) end
function SoundManager.setStepsVolume(volume)  SoundManager.setCategoryVolume("steps", volume) end
function SoundManager.setAmbientVolume(volume) SoundManager.setCategoryVolume("ambient", volume) end

function SoundManager.updateCategoryVolumes(category)
    for _, sound in ipairs(SoundManager.playingSounds) do
        if sound.category == category then sound.source:setVolume(calculateVolume(category)) end
    end
    for _, music in pairs(SoundManager.playingMusic) do
        if music.category == category then music.source:setVolume(calculateVolume(category)) end
    end
end

function SoundManager.updateAllVolumes()
    for category, _ in pairs(SoundManager.categories) do SoundManager.updateCategoryVolumes(category) end
end

-- ###################### --
-- ### UPDATE/CLEANUP ### --
-- ###################### --

function SoundManager.update()
    for i = #SoundManager.playingSounds, 1, -1 do
        local sound = SoundManager.playingSounds[i]
        if not sound.source:isPlaying() and not sound.loop then
            table.remove(SoundManager.playingSounds, i)
        end
    end

    for i = #SoundManager.tempSounds, 1, -1 do
        local temp = SoundManager.tempSounds[i]
        if not temp.source:isPlaying() then
            if temp.unloadWhenDone then
                if temp.isMusic then SoundManager.music[temp.name] = nil
                else SoundManager.sounds[temp.name] = nil end
            end
            table.remove(SoundManager.tempSounds, i)
        end
    end
    
    for name, music in pairs(SoundManager.playingMusic) do
        if not music.source:isPlaying() then
            if music.loop then music.source:play()
            else SoundManager.playingMusic[name] = nil end
        end
    end
    if not next(SoundManager.playingMusic) then SoundManager.currentMusic = nil end
end

-- ###################### --
-- ### FADE FUNCTIONS ### --
-- ###################### --

function SoundManager.fadeIn(name, duration, targetVolume, options)
    options = options or {}
    if SoundManager.isPlaying(name) then return SoundManager.playingMusic[name] or SoundManager.playingSounds[1] end
    if not SoundManager.sounds[name] and not SoundManager.music[name] then return nil end
    
    local sound = SoundManager.play(name, options)
    if sound then
        sound.source:setVolume(0)
        sound.fade = {
            active = true, duration = duration, startVolume = 0,
            targetVolume = targetVolume or calculateVolume(sound.category),
            startTime = love.timer.getTime(), type = "in"
        }
    end
    return sound
end

function SoundManager.fadeOut(name, duration)
    local sound = SoundManager.playingMusic[name]
    for _, s in ipairs(SoundManager.playingSounds) do if s.name == name then sound = s; break end end
    if sound then
        sound.fade = {
            active = true, duration = duration, startVolume = sound.source:getVolume(),
            targetVolume = 0, startTime = love.timer.getTime(), type = "out"
        }
    end
end

function SoundManager.fadeOutAndUnload(name, duration, callback)
    local sound = SoundManager.playingMusic[name] or SoundManager.sounds[name] or SoundManager.music[name]
    if not sound then if callback then callback() end return false end
    
    if not sound.source or not sound.source:isPlaying() then
        SoundManager.unloadSound(name)
        if callback then callback() end
        return true
    end
    
    sound.fade = {
        active = true, duration = duration, startVolume = sound.source:getVolume(),
        targetVolume = 0, startTime = love.timer.getTime(), type = "out",
        callback = function()
            sound.source:stop()
            if SoundManager.playingMusic[name] then
                SoundManager.playingMusic[name] = nil
                SoundManager.currentMusic = nil
            else
                for i, s in ipairs(SoundManager.playingSounds) do
                    if s.name == name then table.remove(SoundManager.playingSounds, i); break end
                end
            end
            SoundManager.unloadSound(name)
            if callback then callback() end
        end
    }
    return true
end

function SoundManager.fadeOutCurrentAndPlay(duration, newMusicName, crossfadeDuration)
    crossfadeDuration = crossfadeDuration or duration
    if SoundManager.currentMusic then
        SoundManager.fadeOutAndUnload(SoundManager.currentMusic.name, duration, function()
            SoundManager.fadeIn(newMusicName, crossfadeDuration)
        end)
    else SoundManager.fadeIn(newMusicName, crossfadeDuration) end
end

function SoundManager.unloadAndPlayNew(unloadName, newName, fadeOutDuration, fadeInDuration, options)
    fadeOutDuration = fadeOutDuration or 1.0
    fadeInDuration = fadeInDuration or fadeOutDuration
    SoundManager.fadeOutAndUnload(unloadName, fadeOutDuration, function()
        SoundManager.fadeIn(newName, fadeInDuration, nil, options)
    end)
end

function SoundManager.shutdown(fadeDuration)
    fadeDuration = fadeDuration or 2.0
    local soundsToFade = {}
    for _, sound in ipairs(SoundManager.playingSounds) do table.insert(soundsToFade, sound) end
    for _, music in pairs(SoundManager.playingMusic) do table.insert(soundsToFade, music) end
    
    if #soundsToFade == 0 then return true end
    
    local completedFades = 0
    local totalFades = #soundsToFade
    
    for _, sound in ipairs(soundsToFade) do
        sound.fade = {
            active = true, duration = fadeDuration, startVolume = sound.source:getVolume(),
            targetVolume = 0, startTime = love.timer.getTime(), type = "out",
            callback = function()
                sound.source:stop()
                completedFades = completedFades + 1
                if completedFades >= totalFades then
                    SoundManager.playingSounds = {}
                    SoundManager.playingMusic = {}
                    SoundManager.currentMusic = nil
                    SoundManager.sounds = {}
                    SoundManager.music = {}
                end
            end
        }
    end
    return true
end

function SoundManager.updateFades()
    local currentTime = love.timer.getTime()
    
    for i = #SoundManager.playingSounds, 1, -1 do
        local sound = SoundManager.playingSounds[i]
        if sound.fade and sound.fade.active then
            local progress = math.min(1, (currentTime - sound.fade.startTime) / sound.fade.duration)
            local newVolume = sound.fade.startVolume + (sound.fade.targetVolume - sound.fade.startVolume) * progress
            sound.source:setVolume(newVolume)
            
            if progress >= 1 then
                sound.fade.active = false
                if sound.fade.targetVolume == 0 then
                    if sound.fade.callback then sound.fade.callback()
                    else sound.source:stop(); table.remove(SoundManager.playingSounds, i) end
                end
                sound.fade = nil
            end
        end
    end
    
    for name, music in pairs(SoundManager.playingMusic) do
        if music.fade and music.fade.active then
            local progress = math.min(1, (currentTime - music.fade.startTime) / music.fade.duration)
            local newVolume = music.fade.startVolume + (music.fade.targetVolume - music.fade.startVolume) * progress
            music.source:setVolume(newVolume)
            
            if progress >= 1 then
                music.fade.active = false
                if music.fade.targetVolume == 0 then
                    if music.fade.callback then music.fade.callback()
                    else
                        music.source:stop()
                        SoundManager.playingMusic[name] = nil
                        SoundManager.currentMusic = nil
                    end
                end
                music.fade = nil
            end
        end
    end
end

-- ######################### --
-- ### UTILITY FUNCTIONS ### --
-- ######################### --

function SoundManager.isPlaying(name)
    for _, sound in ipairs(SoundManager.playingSounds) do
        if sound.name == name and sound.source:isPlaying() then return true end
    end
    return SoundManager.playingMusic[name] ~= nil
end

function SoundManager.getVolume(name)
    for _, sound in ipairs(SoundManager.playingSounds) do
        if sound.name == name then return sound.source:getVolume() end
    end
    return (SoundManager.playingMusic[name] and SoundManager.playingMusic[name].source:getVolume()) or 0
end

function SoundManager.pauseAll()
    for _, sound in ipairs(SoundManager.playingSounds) do sound.source:pause() end
    for _, music in pairs(SoundManager.playingMusic) do music.source:pause() end
end

function SoundManager.resumeAll()
    for _, sound in ipairs(SoundManager.playingSounds) do sound.source:resume() end
    for _, music in pairs(SoundManager.playingMusic) do music.source:resume() end
end

function SoundManager.unloadSound(name)
    SoundManager.stop(name)
    SoundManager.sounds[name] = nil
    SoundManager.music[name] = nil
end

function SoundManager.isLoaded(name)
    return SoundManager.sounds[name] ~= nil or SoundManager.music[name] ~= nil
end

function SoundManager.getStats()
    local loaded = 0
    for _ in pairs(SoundManager.sounds) do loaded = loaded + 1 end
    for _ in pairs(SoundManager.music) do loaded = loaded + 1 end
    
    local playing = #SoundManager.playingSounds + #SoundManager.tempSounds
    for _ in pairs(SoundManager.playingMusic) do playing = playing + 1 end
    
    local musicInstances = 0
    for _ in pairs(SoundManager.playingMusic) do musicInstances = musicInstances + 1 end
    
    return {
        loaded = loaded, playing = playing, tempInstances = #SoundManager.tempSounds,
        regularInstances = #SoundManager.playingSounds, musicInstances = musicInstances
    }
end

-- ###################### --
-- ### INITIALIZATION ### --
-- ###################### --

function SoundManager.init()
    SoundManager.setMasterVolume(1.0)
    SoundManager.setMusicVolume(0.7)
    SoundManager.setSFXVolume(0.8)
    SoundManager.setUIVolume(0.9)
    SoundManager.setStepsVolume(0.6)
    SoundManager.setAmbientVolume(0.5)
end

return SoundManager
