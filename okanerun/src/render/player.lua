local Player = {}

local c = {
    white = {255,255,255,255},
    black = {0,0,0,255},
    g1 = {187, 187, 187, 255},
    g2 = {24, 24, 24, 255},
    plCol = {255, 255, 255, 255},
    ghCol = {0, 255, 255, 255}
}

-- HELPER FUNCTIONS

local function getPlayerSprite(p)
    return tostring(p.anim.frame)
end

local function drawPlayerSprite(p, x, y, z, sx, sy, color)
    local sprite = getPlayerSprite(p)
    local img = fore.assets.getImage(sprite)

    if not img then return end

    local scale = p.sprite.scale or 0.35
    local finalSX = scale * sx
    local finalSY = scale * sy
    
    if p.anim.flipX then finalSX = -finalSX end

    -- Compute horizontal centering and bottom-feet alignment
    local tx = x + p.stat.body.w / 2 + (p.sprite.offset.x * (p.anim.flipX and -1 or 1))
    local ty = y - z + p.sprite.offset.y

    fore.draw2d.imageScaled(sprite, tx, ty, finalSX, finalSY, 0, 128, p.sprite.feetY or 256, color)

    -- Alignment crosshair
    if fore.debug.enabled and fore.data.devmode then
        fore.draw2d.rect(tx - 2, ty - 2, 4, 4, c.black)
        fore.draw2d.rect(tx - 1, ty - 1, 2, 2, c.white)
    end
end


local _ps, _pm, _vs, _opacityFade, _playerCol
local _after, _ghostAlpha

local function drawGhostBody()
    local pc = GameState.player.inv and 120 or 200
    c.ghCol[2] = pc / 1.3
    c.ghCol[3] = pc
    c.ghCol[4] = _ghostAlpha
    drawPlayerSprite(GameState.player, _after.x, _after.y, _after.z, _after.sx, _after.sy, c.ghCol)
end

-- MAIN RENDER INTERFACE

function Player.render()
    local ps = GameState.player
    local pm = ps.stat.body
    local vs = ps.visual
    
    local playerCol = ps.inv and 120 or 200
    local opacityFade = math.max(0, 255 - math.abs(math.min(0, ps.pos.z * 6)))

    -- 1. SHADOW PASS
    fore.queuer.submit(L.SHADOW, ps.pos.y, function()
        fore.draw2d.stencilMask(
            function()
                for _, g in ipairs(GameState.area.ground) do
                    fore.draw2d.rect(g.x, g.y, g.w, g.h, c.white, true)
                end
            end,
            "equal",
            function()
                -- Scale and contract shadow radius dynamically based on jump height
                local shadowZ = math.max(0, ps.pos.z)
                local shrink = math.max(0.45, 1 - shadowZ / 80)
                local w = pm.w * 1.2 * shrink
                local h = pm.h * 0.35 * shrink
                
                local alpha = math.max(60, 160 - ps.pos.z * 1.5)
                local cx = ps.pos.x + pm.w * 0.5
                local cy = ps.pos.y - 2
                
                c.black[4] = alpha
                fore.draw2d.circ(cx - w * 0.5, cy - h * 0.5 + 2, w, h, c.black, true, 16)
                c.black[4] = 255
            end
        )
    end)

    -- 2. ACTOR PASS (Player + Tail)
    fore.queuer.submit(L.ACTOR, ps.pos.y, function()
        -- Core drawing block containing both pieces
        local function drawCharacterBody()
            -- Draw trailing segments behind character body matrix
            c.g1[4] = opacityFade
            c.g2[4] = opacityFade
            fore.draw2d.tail(ps.tail, c.g2, 2, c.g1, 1)
            
            -- Draw character skin
            c.plCol[1] = playerCol
            c.plCol[2] = playerCol
            c.plCol[3] = playerCol
            c.plCol[4] = opacityFade
            drawPlayerSprite(ps, ps.pos.x, ps.pos.y, ps.pos.z, vs.sx, vs.sy, c.plCol)
        end

        -- If falling into pits/negative depth space, crop visuals below the floor boundaries
        if ps.pos.z < 0 then
            fore.draw2d.stencilMask(
                function()
                    for _, g in ipairs(GameState.area.ground) do
                        if g.y >= ps.pos.y then
                            fore.draw2d.rect(g.x, g.y, g.w, g.h, c.white, true)
                        end
                    end
                end,
                "notequal",
                drawCharacterBody
            )
        else
            -- Render normally with clear buffer states
            drawCharacterBody()
        end
    end)

    -- 3. AFTERIMAGES SYSTEM PASS
    for _, a in ipairs(ps.afterimages) do
        fore.queuer.submit(L.ACTOR, a.y, function()
            _ghostAlpha = (a.life / 0.4) * 120
            _after = a
            if a.z < 0 then
                fore.draw2d.stencilMask(
                    function()
                        for _, g in ipairs(GameState.area.ground) do
                            fore.draw2d.rect(g.x, g.y, g.w, g.h, c.white, true)
                        end
                    end,
                    "notequal",
                    drawGhostBody
                )
            else
                drawGhostBody()
            end
        end)
    end
end

return Player
