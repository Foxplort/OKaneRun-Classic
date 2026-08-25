---@class fore.gc
local GC = {}

local collectTimer = 0
local collectInterval = 30
local verbose = false
local dumpers = {}

---Initialize GC system.
---@param config? table { collectInterval: number, verbose: boolean }
function GC.init(config)
    config = config or {}
    collectInterval = config.collectInterval or 30
    verbose = config.verbose or false
    return GC
end

---Register a leak dumper function. Called when GC detects memory growth.
---The function should print diagnostic info about the game's state.
---@param name string Identifier for this dumper
---@param fn function Called with no args, should print() its findings
function GC.registerDumper(name, fn)
    dumpers[name] = fn
end

---Remove a registered dumper.
---@param name string
function GC.removeDumper(name)
    dumpers[name] = nil
end

function GC.update(dt)
    collectgarbage("step", 4096)
    collectTimer = collectTimer + dt
    if collectTimer >= collectInterval then
        collectTimer = 0
        GC.cleanup("Periodic")
    end
end

function GC.cleanup(label)
    local before = gcinfo()
    collectgarbage("collect")
    collectgarbage("collect")
    local after = gcinfo()
    local freed = before - after

    if verbose and label then
        print(("[GC] %s: freed %.1f KB (%.1f -> %.1f KB)"):format(
            label, freed, before, after))
    end

    if verbose and GC._lastCount then
        local growth = after - GC._lastCount
        if growth > 50 then
            print(("[GC] WARNING: Memory grew %.1f KB since last cleanup (leak suspected)"):format(growth))
            GC._dumpLeaks()
        end
    end
    GC._lastCount = after
    return freed
end

---Engine-level diagnostics (assets, audio, hooks).
---Games add their own via GC.registerDumper().
function GC._dumpLeaks()
    -- Engine internals
    local imgCount = 0
    for _ in pairs(fore.assets.images) do imgCount = imgCount + 1 end
    local sndCount = 0
    for _ in pairs(fore.assets.sounds) do sndCount = sndCount + 1 end
    local regCount = 0
    for _ in pairs(fore.assets.asset_registry) do regCount = regCount + 1 end
    local playCount = 0
    for _ in pairs(fore.audio.playing) do playCount = playCount + 1 end
    local provCount = 0
    for _ in pairs(fore.debug.providers) do provCount = provCount + 1 end

    print("[GC] Snapshot: " .. tostring(gcinfo()) .. " KB")
    if imgCount > 0 then print("  images = " .. imgCount) end
    if sndCount > 0 then print("  sounds = " .. sndCount) end
    if regCount > 0 then print("  asset_registry = " .. regCount) end
    if playCount > 0 then print("  audio_playing = " .. playCount) end
    if provCount > 0 then print("  debug_providers = " .. provCount) end

    for hookName, hooks in pairs(fore.hooks) do
        if #hooks > 0 then print("  hooks_" .. hookName .. " = " .. #hooks) end
    end

    -- Game-specific dumpers
    for name, fn in pairs(dumpers) do
        local ok, err = pcall(fn)
        if not ok then
            print("  [dumper '" .. name .. "' error: " .. tostring(err) .. "]")
        end
    end
end

function GC.getMemoryKB()
    return gcinfo()
end

return GC
