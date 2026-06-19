local Debug = {}

Debug.enabled = false
Debug.providers = {}
Debug.detailLevel = 1
Debug.maxDetailLevel = 3
Debug.page = 1
Debug.maxPages = 2

Debug.keys = {
    nextPage = "tab", prevPage = "rshift",
    increaseDetail = "=", decreaseDetail = "-",
}

Debug.dc = 0

-- Performance tracking
local frameTimes = {}
local frameHistory = {}
local maxHistory = 180
local stats = {
    fps = 0, dt = 0, frame = 0,
    frameMin = 0, frameMax = 0, frameAvg = 0,
    frame1low = 0, frame01low = 0,
    ram = { lua = 0, gpu = 0, audio = 0, total = 0 },
    draws = 0, canvases = 0, images = 0,
    audio = { loaded = 0, playing = 0 },
    gcCount = 0, gcTime = 0
}

local timer = 0
local updateRate = 0.2
local gcTimer = 0
local gcRate = 2.0

local function estAudioMem()
    local total = 0
    for _ in pairs(fore.audio.sounds) do total = total + 0.3 end
    return total
end

function Debug.add(n, fn) Debug.providers[n] = fn end
function Debug.remove(n) Debug.providers[n] = nil end

function Debug.keypressed(k)
    if not Debug.enabled then return end
    if k == Debug.keys.nextPage then
        Debug.page = Debug.page % Debug.maxPages + 1
    elseif k == Debug.keys.prevPage then
        Debug.page = Debug.page == 1 and Debug.maxPages or Debug.page - 1
    elseif k == Debug.keys.increaseDetail then
        Debug.detailLevel = math.min(Debug.detailLevel + 1, Debug.maxDetailLevel)
    elseif k == Debug.keys.decreaseDetail then
        Debug.detailLevel = math.max(Debug.detailLevel - 1, 1)
    end
end

function Debug.update()
    if not Debug.enabled then return end
    
    local dt = love.timer.getDelta()
    local frameMs = dt * 1000
    
    table.insert(frameTimes, frameMs)
    if #frameTimes > maxHistory then table.remove(frameTimes, 1) end
    if #frameTimes % 3 == 0 then frameHistory = {unpack(frameTimes)} end
    
    timer = timer + dt
    if timer >= updateRate then
        local gStats = love.graphics.getStats()
        local aStats = fore.audio.getStats()
        
        stats.fps = love.timer.getFPS()
        stats.frame = frameMs
        stats.draws = Debug.dc
        stats.canvases = gStats.canvases
        stats.images = gStats.images
        stats.ram.gpu = gStats.texturememory / 1024 / 1024
        stats.audio.loaded = aStats.loaded
        stats.audio.playing = aStats.playing
        stats.ram.audio = estAudioMem()
        
        if #frameTimes > 30 then
            local sorted = {unpack(frameTimes)}
            table.sort(sorted)
            stats.frameMin = sorted[1]
            stats.frameMax = sorted[#sorted]
            local sum = 0; for _,v in ipairs(sorted) do sum = sum + v end
            stats.frameAvg = sum / #sorted
            stats.frame1low = sorted[math.max(1, math.floor(#sorted * 0.99))]
            stats.frame01low = sorted[math.max(1, math.floor(#sorted * 0.999))]
        end
        timer = 0
    end
    
    gcTimer = gcTimer + dt
    if gcTimer >= gcRate then
        stats.ram.lua = collectgarbage("count") / 1024
        stats.gcCount = collectgarbage("count")
        stats.ram.total = stats.ram.lua + stats.ram.gpu + stats.ram.audio
        local start = fore.time.getTicks()
        collectgarbage("step", 1024 * 1024)
        stats.gcTime = (fore.time.getTicks() - start) * 1000
        gcTimer = 0
    end
end

function Debug.draw()
    if not Debug.enabled then return end
    
    local uiScale = math.max(1, fore.data.scale / 1.5 + 0.2)
    local x, y, lh, pad = 6 * uiScale, 6 * uiScale, 12 * uiScale, 4 * uiScale
    local lines = {}
    
    -- Header
    local hdr = string.format(fore.conf.name .. " [%s] | %d/%d", fore.conf.version, Debug.page, Debug.maxPages)
    local ehdr = string.format("Fore Engine [%s] | Lv%d", fore.version, Debug.detailLevel)
    local backendHdr = string.format("Backend: %s", fore.backend)
    table.insert(lines, hdr)
    table.insert(lines, ehdr)
    table.insert(lines, backendHdr)
    table.insert(lines, string.rep("-", math.max(#hdr, #ehdr, #backendHdr)))
    
    -- Page 1: Performance
    if Debug.page == 1 then
        table.insert(lines, string.format("FPS:%d | %.1fms", stats.fps, stats.frame))
        if Debug.detailLevel >= 1 then
            table.insert(lines, string.format("RAM:L%.1f G%.1f A%.1f =%.1fMB",
                stats.ram.lua, stats.ram.gpu, stats.ram.audio, stats.ram.total))
        end
        if Debug.detailLevel >= 2 then
            table.insert(lines, string.format("1%%:%.0ffps | 0.1%%:%.0ffps",
                1000/stats.frame1low, 1000/stats.frame01low))
            table.insert(lines, string.format("D:%d C:%d I:%d", stats.draws, stats.canvases, stats.images))
            table.insert(lines, string.format("A:%d/%d | GC:%.2fms", stats.audio.playing, stats.audio.loaded, stats.gcTime))
        end
        if Debug.detailLevel >= 3 then
            table.insert(lines, string.format("min:%.1f max:%.1f avg:%.1fms",
                stats.frameMin, stats.frameMax, stats.frameAvg))
            table.insert(lines, string.format("GC:%.0f | %dx%d", stats.gcCount, fore.data.width, fore.data.height))
        end
        
    -- Page 2: Providers
    else
        for name, fn in pairs(Debug.providers) do
            local ok, data = pcall(fn)
            if ok and data then
                table.insert(lines, "["..name.."]")
                for _, l in ipairs(data) do
                    if Debug.detailLevel >= 2 or not l:match(":") then
                        table.insert(lines, "  "..l)
                    end
                end
            end
        end
    end
    
    -- Panel size
    fore.graphics.setFontScale(uiScale)
    local font = love.graphics.getFont()
    local w = 0; for _,l in ipairs(lines) do w = math.max(w, font:getWidth(l) * uiScale) end
    w = w + pad * 2
    local graphH = (Debug.page==1 and Debug.detailLevel>=2 and #frameHistory>1) and (45 * uiScale) or 0
    local h = #lines * lh + pad * 2 + graphH + 10 * uiScale
    
    -- Panel bg
    fore.graphics.rect(x, y, w, h, {0,0,0,200})
    fore.graphics.rect(x-1, y-1, w+2, h+2, {255,255,255,40}, false)
    
    -- Text
    for i,l in ipairs(lines) do
        local col = l:find("^%-") and {200,200,200} or {255,255,255}
        fore.graphics.text(l, x+pad, y+pad + (i-1)*lh, uiScale, col)
    end
    
    -- Graph
    if graphH > 0 then
        local gx, gy = x+pad, y + h - graphH - 2 * uiScale
        local gw = w - pad*2
        fore.graphics.text("Frame (ms)", gx, gy - 12 * uiScale, 0.7 * uiScale, {200,200,200})
        fore.graphics.graph(frameHistory, gx, gy, gw, graphH - 15 * uiScale, {255,200,100}, 0, 33.33, 16.67)
        fore.graphics.text("60", gx+gw - 20 * uiScale, gy - 10 * uiScale, 0.6 * uiScale, {100,255,100})
    end
    
    -- Hint with background
    local hint = "K:close Tab:page +/-:detail"
    local hw, hh = font:getWidth(hint) * uiScale, font:getHeight() * uiScale
    fore.graphics.rect(x, y+h + 2 * uiScale, hw + 6 * uiScale, hh + 4 * uiScale, {0,0,0,180})
    fore.graphics.text(hint, x + 3 * uiScale, y+h + 4 * uiScale, uiScale, {200,200,200})
end

return Debug