---@class fore.audio
---@field masterVolume number
---@field categories table<string, AudioCategory>
---@field sounds table<string, AudioClip>
---@field playing table<string, AudioInstance>
local Audio = {
    masterVolume = 1.0,
    
    ---@type table<string, AudioCategory>
    categories = {
        music = { volume = 0.7, concurrent = false },
        sfx   = { volume = 0.8, concurrent = true },
        ui    = { volume = 0.9, concurrent = true },
        voice = { volume = 0.8, concurrent = true },
        ambient = { volume = 0.5, concurrent = false }
    },
    
    ---@type table<string, AudioClip>
    sounds = {},
    
    ---@type table<string, AudioInstance>
    playing = {}
}

---@class AudioCategory
---@field volume number
---@field concurrent boolean

---@class AudioClip
---@field name string 
---@field path string
---@field stream boolean  -- true for music, false for SFX
---@field source love.Source
---@field category string

---@class AudioInstance
---@field source love.Source
---@field clip AudioClip
---@field category string
---@field baseVolume number
---@field loop boolean
---@field fade? {type: "in"|"out", start: number, duration: number, from: number, to: number, callback?: function}

---@class AudioPlayOptions
---@field category? string
---@field volume? number
---@field pitch? number
---@field pan? number
---@field loop? boolean
---@field fadeIn? number
---@field fadeOut? number  -- for stop/fade out
---@field concurrent? boolean  -- override category concurrent setting

---Load a sound (user decides streaming)
---@param name string
---@param path string
---@param stream? boolean  -- true for music/long sounds, false for SFX
---@param category? string  -- defaults to "sfx" for static, "music" for stream
---@return AudioClip
function Audio.load(name, path, stream, category)
    stream = stream or false
    category = category or (stream and "music" or "sfx")
    
    local clip = {
        name = name,
        path = path,
        stream = stream,
        category = category,
        source = love.audio.newSource(path, stream and "stream" or "static")
    }
    Audio.sounds[name] = clip
    return clip
end

---Play a sound
---@param name string
---@param opts? AudioPlayOptions
---@return AudioInstance?
function Audio.play(name, opts)
    opts = opts or {}
    
    local clip = Audio.sounds[name]
    if not clip then
        print(("Audio '%s' not found"):format(name))
        return nil
    end
    
    local category = opts.category or clip.category
    local cat = Audio.categories[category] or Audio.categories.sfx
    local concurrent = opts.concurrent ~= nil and opts.concurrent or cat.concurrent
    
    -- Stop others in category if not concurrent
    if not concurrent then
        Audio.stopCategory(category, opts.fadeOut)
    end
    
    -- Create instance
    local instance = {
        source = clip.source:clone(),
        clip = clip,
        category = category,
        baseVolume = opts.volume or 1.0,
        loop = opts.loop or false
    }
    
    -- Apply initial settings
    instance.source:setLooping(instance.loop)
    instance.source:setVolume(Audio:_calcVolume(instance, category))
    if opts.pitch then instance.source:setPitch(opts.pitch) end
    if opts.pan then instance.source:setPan(opts.pan) end
    
    -- Handle fade in
    if opts.fadeIn then
        instance.source:setVolume(0)
        instance.fade = {
            type = "in",
            start = love.timer.getTime(),
            duration = opts.fadeIn,
            from = 0,
            to = Audio:_calcVolume(instance, category)
        }
    end
    
    -- Generate ID and store
    local id = name .. "_" .. love.timer.getTime()
    Audio.playing[id] = instance
    instance.source:play()
    
    return instance
end

---Play and auto-delete after (one-shot)
---@param name string
---@param opts? AudioPlayOptions
function Audio.playOnce(name, opts)
    local instance = Audio.play(name, opts)
    if instance then
        instance.autoDelete = true
    end
end

---Fade out a specific sound and unload it after
---@param name string
---@param fadeOut number Duration in seconds
---@param callback? function Optional function to call after unload
---@return boolean success
function Audio.fadeOutAndUnload(name, fadeOut, callback)
    -- Find the instance
    local instanceId = nil
    local instance = nil
    
    for id, inst in pairs(Audio.playing) do
        if id:match("^" .. name) then
            instanceId = id
            instance = inst
            break
        end
    end
    
    if not instance then
        -- Not playing, just unload if exists
        if Audio.sounds[name] then
            Audio.sounds[name] = nil
            if callback then callback() end
        end
        return false
    end
    
    -- Set up fade out with unload callback
    instance.fade = {
        type = "out",
        start = love.timer.getTime(),
        duration = fadeOut,
        from = instance.source:getVolume(),
        to = 0,
        callback = function()
            instance.source:stop()
            Audio.playing[instanceId] = nil
            -- Unload the sound
            Audio.sounds[name] = nil
            if callback then callback() end
        end
    }
    
    return true
end

---Fade out current music and play new one (with unload)
---@param newName string
---@param fadeOut? number
---@param fadeIn? number
---@param keepOld? boolean If false, unload old music
function Audio.crossfade(newName, fadeOut, fadeIn, keepOld)
    fadeOut = fadeOut or 1.0
    fadeIn = fadeIn or fadeOut
    
    -- Find current music
    local currentMusic = nil
    local currentId = nil
    for id, instance in pairs(Audio.playing) do
        if instance.category == "music" or instance.category == "ambient" then
            currentMusic = instance
            currentId = id
            break
        end
    end
    
    if currentMusic then
        -- Fade out current
        currentMusic.fade = {
            type = "out",
            start = love.timer.getTime(),
            duration = fadeOut,
            from = currentMusic.source:getVolume(),
            to = 0,
            callback = function()
                currentMusic.source:stop()
                Audio.playing[currentId] = nil
                if not keepOld and currentMusic.clip and currentMusic.clip.name then
                    Audio.sounds[currentMusic.clip.name] = nil
                end
                -- Play new music after old fades out
                Audio.play(newName, { 
                    loop = true, 
                    fadeIn = fadeIn,
                    category = "music"
                })
            end
        }
    else
        -- No current music, just play new
        Audio.play(newName, { loop = true, fadeIn = fadeIn, category = "music" })
    end
end

---Stop all music and unload it
---@param fadeOut? number
function Audio.stopAndUnloadAllMusic(fadeOut)
    fadeOut = fadeOut or 1.0
    local musicToUnload = {}
    
    -- Find all music/ambient to unload
    for name, clip in pairs(Audio.sounds) do
        if clip.category == "music" or clip.category == "ambient" then
            table.insert(musicToUnload, name)
        end
    end
    
    -- Stop and unload each
    for _, name in ipairs(musicToUnload) do
        Audio.fadeOutAndUnload(name, fadeOut)
    end
end

---Stop specific sound or all in category
---@param name? string
---@param category? string
---@param fadeOut? number
function Audio.stop(name, category, fadeOut)
    if not name and not category then
        -- Stop all
        for id, instance in pairs(Audio.playing) do
            Audio:_stopInstance(id, instance, fadeOut)
        end
        return
    end
    
    for id, instance in pairs(Audio.playing) do
        if (name and id:match("^" .. name)) or 
           (category and instance.category == category) then
            Audio:_stopInstance(id, instance, fadeOut)
        end
    end
end

---Stop all sounds in a category
---@param category string
---@param fadeOut? number
function Audio.stopCategory(category, fadeOut)
    Audio.stop(nil, category, fadeOut)
end

---Set category volume
---@param category string
---@param volume number
function Audio.setCategoryVolume(category, volume)
    if Audio.categories[category] then
        Audio.categories[category].volume = math.max(0, math.min(1, volume))
        Audio:_updateVolumes(category)
    end
end

---Set master volume
---@param volume number
function Audio.setMasterVolume(volume)
    Audio.masterVolume = math.max(0, math.min(1, volume))
    Audio:_updateVolumes()
end

---Update (handle fades, cleanup)
function Audio.update(dt)
    local now = love.timer.getTime()
    
    for id, instance in pairs(Audio.playing) do
        -- Handle fades
        if instance.fade then
            local elapsed = now - instance.fade.start
            local progress = math.min(1, elapsed / instance.fade.duration)
            
            local newVol = instance.fade.from + (instance.fade.to - instance.fade.from) * progress
            instance.source:setVolume(newVol)
            
            if progress >= 1 then
                if instance.fade.type == "out" then
                    instance.source:stop()
                    if instance.fade.callback then instance.fade.callback() end
                    Audio.playing[id] = nil
                else
                    instance.fade = nil
                end
            end
        end
        
        -- Remove finished sounds
        if not instance.source:isPlaying() and not instance.loop then
            if instance.autoDelete and instance.clip and instance.clip.name then
                -- Delete the clip if it was a one-shot
                Audio.sounds[instance.clip.name] = nil
            end
            Audio.playing[id] = nil
        end
    end
end

-- Smart Load/Unload System

---@class AudioLoadPlan
---@field keep string[]  -- sounds to keep
---@field load table<string, string>  -- name -> path for new sounds
---@field unload string[]  -- sounds to remove

---Plan audio changes (checks what needs loading/unloading)
---@param wanted table<string, string>  -- desired name->path mapping
---@return AudioLoadPlan
function Audio.plan(wanted)
    local plan = {
        keep = {},
        load = {},
        unload = {}
    }
    
    -- Find what to keep vs load
    for name, path in pairs(wanted) do
        if Audio.sounds[name] and Audio.sounds[name].path == path then
            table.insert(plan.keep, name)  -- Same name & path, keep
        else
            plan.load[name] = path  -- New or changed path
        end
    end
    
    -- Find what to unload
    for name, _ in pairs(Audio.sounds) do
        if not wanted[name] then
            table.insert(plan.unload, name)  -- Not wanted anymore
        end
    end
    
    return plan
end

---Execute a load plan
---@param plan AudioLoadPlan
---@param fadeOut? number  -- fade out unloaded sounds
function Audio.execute(plan, fadeOut)
    -- Unload unwanted sounds
    for _, name in ipairs(plan.unload) do
        Audio.stop(name, nil, fadeOut)  -- Stop with fade
        Audio.sounds[name] = nil
    end
    
    -- Load new sounds
    for name, path in pairs(plan.load) do
        -- Determine if stream based on path/name?
        local stream = name:match("music") or name:match("ambient") or false
        Audio.load(name, path, stream)
    end
end

---Switch to a new set of sounds smoothly
---@param wanted table<string, string>
---@param fadeOut? number
function Audio.transition(wanted, fadeOut)
    local plan = Audio.plan(wanted)
    Audio.execute(plan, fadeOut)
end

-- Private methods
function Audio:_calcVolume(instance, category)
    local cat = Audio.categories[category or instance.category] or Audio.categories.sfx
    return instance.baseVolume * cat.volume * Audio.masterVolume
end

function Audio:_updateVolumes(category)
    for _, instance in pairs(Audio.playing) do
        if not category or instance.category == category then
            instance.source:setVolume(Audio:_calcVolume(instance))
        end
    end
end

function Audio:_stopInstance(id, instance, fadeOut)
    if fadeOut then
        instance.fade = {
            type = "out",
            start = love.timer.getTime(),
            duration = fadeOut,
            from = instance.source:getVolume(),
            to = 0,
            callback = function()
                instance.source:stop()
                Audio.playing[id] = nil
            end
        }
    else
        instance.source:stop()
        Audio.playing[id] = nil
    end
end

---Get audio statistics for debug
---@return table
function Audio.getStats()
    local loaded = 0
    for _ in pairs(Audio.sounds) do loaded = loaded + 1 end
    
    local playing = 0
    for _ in pairs(Audio.playing) do playing = playing + 1 end
    
    -- Count by category
    local byCategory = {}
    for _, instance in pairs(Audio.playing) do
        byCategory[instance.category] = (byCategory[instance.category] or 0) + 1
    end
    
    return {
        loaded = loaded,
        playing = playing,
        byCategory = byCategory,
        masterVolume = Audio.masterVolume,
        categories = Audio.categories
    }
end

return Audio
