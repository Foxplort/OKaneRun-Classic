local Player = {}

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
        fore.draw2d.rect(tx - 2, ty - 2, 4, 4, {0, 0, 0, 255})
        fore.draw2d.rect(tx - 1, ty - 1, 2, 2, {255, 255, 255, 255})
    end
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
                    fore.draw2d.rect(g.x, g.y, g.w, g.h, {255, 255, 255, 255}, true)
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

                fore.draw2d.circ(cx - w * 0.5, cy - h * 0.5 + 2, w, h, {0, 0, 0, alpha}, true, 16)
            end
        )
    end)

    -- 2. ACTOR PASS (Player + Tail)
    fore.queuer.submit(L.ACTOR, ps.pos.y, function()
        -- Core drawing block containing both pieces
        local function drawCharacterBody()
            -- Draw trailing segments behind character body matrix
            fore.draw2d.tail(ps.tail, {24, 24, 24, opacityFade}, 2, {187, 187, 187, opacityFade}, 1) 
            
            -- Draw character skin
            drawPlayerSprite(
                ps, ps.pos.x, ps.pos.y, ps.pos.z, vs.sx, vs.sy,
                {playerCol, playerCol, playerCol, opacityFade}
            )
        end

        -- If falling into pits/negative depth space, crop visuals below the floor boundaries
        if ps.pos.z < 0 then
            fore.draw2d.stencilMask(
                function()
                    for _, g in ipairs(GameState.area.ground) do
                        if g.y >= ps.pos.y then
                            fore.draw2d.rect(g.x, g.y, g.w, g.h, {255, 255, 255, 255}, true)
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
            local alpha = (a.life / 0.4) * 120

            local function drawGhostBody()
                drawPlayerSprite(ps, a.x, a.y, a.z, a.sx, a.sy, {0, playerCol / 1.3, playerCol, alpha})
            end

            if a.z < 0 then
                fore.draw2d.stencilMask(
                    function()
                        for _, g in ipairs(GameState.area.ground) do
                            fore.draw2d.rect(g.x, g.y, g.w, g.h, {255, 255, 255, 255}, true)
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
