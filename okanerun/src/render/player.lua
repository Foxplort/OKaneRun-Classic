local Player = {}

local function getPlayerSprite(p)
    return tostring(p.anim.frame)
end

local function drawPlayerSprite(p, x, y, z, sx, sy, color)
    local sprite = getPlayerSprite(p)
    local img = fore.graphics.getImage(sprite)
    
    if not img then return end

    local scale = p.sprite.scale or 0.35
    local finalSX = scale * sx
    local finalSY = scale * sy
    
    if p.anim.flipX then finalSX = -finalSX end

    -- Center horizontally (p.stat.body.w/2), align bottom to feet
    -- Offset is for fine-tuning
    local tx = x + p.stat.body.w / 2 + (p.sprite.offset.x * (p.anim.flipX and -1 or 1))
    local ty = y - z + p.sprite.offset.y

    -- Align bottom-center (or feet-center) of the image
    fore.graphics.imageScaled(sprite, tx, ty, finalSX, finalSY, 0, 128, p.sprite.feetY or 256, color)

    if fore.debug.enabled then
        fore.graphics.rect(tx - 2, ty - 2, 4, 4, {0, 0, 0})
        fore.graphics.rect(tx - 1, ty - 1, 2, 2, {255, 255, 255})
    end
end

function Player.render()
    -- shadow
    fore.queuer.submit(L.SHADOW, GameState.player.pos.y, function()
        love.graphics.stencil(function()
            for _, g in ipairs(GameState.area.ground) do
                love.graphics.rectangle("fill", g.x, g.y, g.w, g.h)
            end
        end, "replace", 1)
        love.graphics.setStencilTest("equal", 1) -- "Only draw where ground IS"


        local z = GameState.player.pos.z
        local pm = GameState.player.stat.body

        -- base shadow size from player size
        local baseW = pm.w * 1.2
        local baseH = pm.h * 0.35

        -- shrink with jump
        local shadowZ = math.max(0, GameState.player.pos.z) -- Don't go below floor
        local shrink = math.max(0.45, 1 - shadowZ / 80)

        local w = baseW * shrink
        local h = baseH * shrink

        -- fade slightly with height
        local alpha = math.max(60, 160 - z * 1.5)

        -- center under feet
        local cx = GameState.player.pos.x + pm.w * 0.5
        local cy = GameState.player.pos.y - 2

        fore.graphics.circ(
            cx - w * 0.5,
            cy - h * 0.5 + 2,
            w,
            h,
            {0, 0, 0, alpha},
            true, 16
        )

        love.graphics.setStencilTest()
    end)

    
    -- tail
    fore.queuer.submit(
        L.ACTOR,
        GameState.player.pos.y-0.01,
        function()
            local alpha = 255-math.abs(math.min(0, GameState.player.pos.z*6))
            fore.graphics.tail(GameState.player.tail, {24, 24, 24, alpha}, 2, {187, 187, 187, alpha}, 1) 
        end
    )


    -- player
    local pm = GameState.player.stat.body
    local vs = GameState.player.visual
    local ps = GameState.player
    
    local playerCol = 200
    if GameState.player.inv then playerCol = 120 end
    
    fore.queuer.submit(L.ACTOR, GameState.player.pos.y, function()
        if GameState.player.pos.z < 0 then
            love.graphics.stencil(function()
                for _, g in ipairs(GameState.area.ground) do
                    love.graphics.rectangle("fill", g.x, g.y, g.w, g.h-(GameState.player.sprite.feetY*GameState.player.sprite.scale))
                end
            end, "replace", 1)
            -- "notequal 1" means: Only draw where the stencil (ground) is NOT
            love.graphics.setStencilTest("notequal", 1)
        end

        drawPlayerSprite(
            ps,
            ps.pos.x, ps.pos.y, ps.pos.z,
            vs.sx, vs.sy,
            {playerCol, playerCol, playerCol, 255-math.abs(math.min(0, ps.pos.z*6))}
        )

        love.graphics.setStencilTest() -- Reset stencil
    end)

    for _, a in ipairs(GameState.player.afterimages) do
        fore.queuer.submit(L.ACTOR, a.y, function()
            local alpha = (a.life / 0.4) * 120

            if a.z < 0 then
                love.graphics.stencil(function()
                    for _, g in ipairs(GameState.area.ground) do
                        love.graphics.rectangle("fill", g.x, g.y, g.w, g.h-GameState.player.stat.body.h)
                    end
                end, "replace", 1)
                -- "notequal 1" means: Only draw where the stencil (ground) is NOT
                love.graphics.setStencilTest("notequal", 1)
            end

            drawPlayerSprite(
                ps, -- use player state for current frame/state, which is technically incorrect for an afterimage but works for now
                a.x, a.y, a.z,
                a.sx, a.sy,
                {0, playerCol/1.3, playerCol, alpha}
            )

            love.graphics.setStencilTest()
        end)
    end
end

return Player
