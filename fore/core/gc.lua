---@class fore.gc
local GC = {}

local collectTimer = 0
local collectInterval = 30
local verbose = false

---Initialize GC system.
---@param config? table { collectInterval: number, verbose: boolean }
function GC.init(config)
    config = config or {}
    collectInterval = config.collectInterval or 30
    verbose = config.verbose or false
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

function GC._dumpLeaks()
    local counts = {}
    local imgCount = 0
    for _ in pairs(fore.assets.images) do imgCount = imgCount + 1 end
    counts.images = imgCount
    local sndCount = 0
    for _ in pairs(fore.assets.sounds) do sndCount = sndCount + 1 end
    counts.sounds = sndCount
    local regCount = 0
    for _ in pairs(fore.assets.asset_registry) do regCount = regCount + 1 end
    counts.asset_registry = regCount
    local playCount = 0
    for _ in pairs(fore.audio.playing) do playCount = playCount + 1 end
    counts.audio_playing = playCount
    local provCount = 0
    for _ in pairs(fore.debug.providers) do provCount = provCount + 1 end
    counts.debug_providers = provCount
    for hookName, hooks in pairs(fore.hooks) do
        if #hooks > 0 then counts["hooks_" .. hookName] = #hooks end
    end
    if GameState and GameState.area then
        counts.area_ground = GameState.area.ground and #GameState.area.ground or 0
        counts.area_coins = GameState.area.coins and #GameState.area.coins or 0
        counts.area_cores = GameState.area.cores and #GameState.area.cores or 0
    end
    if GameState and GameState.player then
        local p = GameState.player
        local effCount = 0
        if p.effects then for _ in pairs(p.effects) do effCount = effCount + 1 end end
        counts.player_effects = effCount
        counts.player_zHistory = p.zHistory and #p.zHistory or 0
    end
    print("[GC] Snapshot: " .. tostring(gcinfo()) .. " KB")
    for k, v in pairs(counts) do
        if v > 0 then print("  " .. k .. " = " .. v) end
    end
end

function GC.getMemoryKB()
    return gcinfo()
end

return GC
