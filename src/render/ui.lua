local UI = {}

local function drawCoinIndicator()
    local p = GameState.player
    local coins = GameState.area.coins
    
    if #coins == 0 then return end

    local centerX = Game.width - 40
    local centerY = 40
    
    local radius = 20
    local thickness = 2
    local segmentSize = 0.2

    Fx.r.arc(centerX, centerY, radius, 0, math.pi * 2, {255, 255, 255, 30}, "open", false, 32, thickness)

    for _, coin in ipairs(coins) do
        local angle = math.atan2(coin.y - p.pos.y, coin.x - p.pos.x)
        
        Fx.r.arc(
            centerX,
            centerY,
            radius - 0.5,
            angle - segmentSize/2,
            angle + segmentSize/2,
            {255, 255, 0, 255},
            "open",
            false,
            10,
            thickness + 1
        )
    end
end

local function drawHealthIndicator()
    local hp = GameState.player.hp.count
    local maxHp = GameState.player.hp.max
    if maxHp <= 0 then return end

    local ratio = math.max(0, math.min(1, hp / maxHp))

    -- Position: bottom-left, circle center off-screen
    local centerX = 0
    local centerY = Game.height
    local radius = 60
    local thickness = 10

    local startAngle = -math.pi / 2
    local endAngle = 0
    local filledAngle = startAngle + (endAngle - startAngle) * ratio

    -- Background arc
    Fx.r.arc(
        centerX,
        centerY,
        radius,
        startAngle,
        endAngle,
        {63, 0, 46, 120},
        "open",
        false,
        32,
        thickness
    )

    -- Filled HP arc
    Fx.r.arc(
        centerX,
        centerY,
        radius,
        startAngle,
        filledAngle,
        {255, 0, 127, 255},
        "open",
        false,
        32,
        thickness
    )

    -- HP text
    Fx.r.text(
        hp .. "/" .. maxHp,
        10,
        Game.height - 18,
        1,
        255,
        90,
        "left"
    )
end

function UI.draw()
    drawHealthIndicator()

    -- coin count
    Fx.r.text(tostring(GameState.player.coins) .. "c", Game.width-80, 35, 1, 255, 80, "center")

    drawCoinIndicator()
end

return UI
