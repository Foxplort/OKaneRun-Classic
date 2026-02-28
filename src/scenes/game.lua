local Scene = {}

-- ################# --
-- ### VARIABLES ### --
-- ################# --

local gameData = nil
local loadedImages = {}
local pause = false
local deathPause = false
local menu = nil
local menuStack = nil
local monoShader = nil

local DEPOSIT_TIME = 0.8
local DECAY_TIME = 2

-- ######################## --
-- ### HELPER FUNCTIONS ### --
-- ######################## --

local function followTarget(coin, tx, ty, tz, dt)
    local dx = coin.x - tx
    local dy = coin.y - ty
    local dz = coin.z - tz

    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
    if dist == 0 then return end

    local desired = coin.spacing
    local diff = dist - desired

    -- Soft clamp
    local pull = Fx.m.clamp(diff * 8, -200, 200)

    coin.x = coin.x - (dx / dist) * pull * dt
    coin.y = coin.y - (dy / dist) * pull * dt
    --coin.z = coin.z - (dz / dist) * pull * dt
    coin.z = coin.z + (tz - coin.z) * 6 * dt
end

-- Deep copy + apply modifiers recursively
local function applyMods(base, mod)
    local stat = {}
    for k, v in pairs(base) do
        if type(v) == "table" then
            stat[k] = applyMods(v, mod[k] or {})
        else
            local modValue = mod[k] or {add = 0, mul = 1}
            stat[k] = (v + (modValue.add or 0)) * (modValue.mul or 1)
        end
    end
    return stat
end

local function statPerp()
    GameState.player.stat = applyMods(GameState.player.base, GameState.player.mod)
end

local function getActiveCore(hb)
    for _, c in ipairs(GameState.area.cores) do
        local zone = { x = c.x, y = c.y, w = c.w, h = c.h }
        if Fx.m.aabb(hb, zone) then
            return c
        end
    end
    return nil
end

-- ######################### --
-- ### SUBMAIN FUNCTIONS ### --
-- ######################### --

local function damageHandler(dt)
    -- Fall into the pit
    if GameState.player.pos.z <= -150 then
        GameState.player.hp.count = GameState.player.hp.count - 1

        -- Safe Teleport
        GameState.player.pos.x = GameState.area.spawn.x - GameState.player.base.body.hitbox.w/2
        GameState.player.pos.y = GameState.area.spawn.y - GameState.player.base.body.hitbox.h/2
        GameState.player.pos.z = 40

        -- Coins teleport
        for i, coin in ipairs(GameState.player.coinChain) do
            coin.x = GameState.player.pos.x
            coin.y = GameState.player.pos.y
            coin.z = GameState.player.pos.z
        end

        -- Effects
        gameData.systems.camera.addShake("world", 3)
        gameData.systems.camera.addShake("ui", 3)
    end

    -- Getting the results
    if GameState.player.hp.count <= 0 then
        GameState.player.dead = true
    end
end

-- ###################### --
-- ### MAIN FUNCTIONS ### --
-- ###################### --

function Scene.enter()
    -- LOAD THE LEVEL
    local levelList = require("src.data.levels")
    GameState.area = Fx.ll.load("src/data/levels/" .. levelList[math.random(#levelList)] .. ".lua")
    --GameState.area = Fx.ll.load("src/data/levels/cheezeLand.lua")

    -- RESET VARIABLES
    pause = false
    deathPause = false
    GameState.player.pos.x = GameState.area.spawn.x - GameState.player.base.body.hitbox.w/2
    GameState.player.pos.y = GameState.area.spawn.y - GameState.player.base.body.hitbox.h/2
    GameState.player.pos.z = 40
    GameState.player.coinChain = {}

    gameData = {
        render = {
            player = require("src.render.player"),
            world = require("src.render.world"),
            ui = require("src.render.ui"),
        },
        systems = {
            camera = require("src.systems.camera"),
            tail = require("src.systems.playerTail"),
            particles = require("src.systems.particles"),
        },
        game = {
            effects = require("src.game.effects"),
            effectSys = require("src.game.effectSystem"),
            effectUI = require("src.game.effectUI"),
        },
    }

    gameData.systems.camera.init(GameState.area.mapWidth, GameState.area.mapHeight)
    gameData.game.effectUI.load(gameData.game.effects, gameData.game.effectSys)

    for id, eff in pairs(gameData.game.effects) do
        local path = "assets/images/buffs/" .. eff.id .. ".png"
        if love.filesystem.getInfo(path) then
            Fx.r.loadImage(eff.id, path)
            table.insert(loadedImages, eff.id)
        end
    end

    Fx.debug.add("Player", function()
        local p = GameState.player
        return {
            string.format("pos: %.1f / %.1f", p.pos.x, p.pos.y),
            string.format("z: %.1f  vz: %.2f", p.pos.z or 0, p.vel.z or 0),
            "grounded: " .. tostring(p.grounded),
            "coins: " .. p.coins
        }
    end)

    local MenuSys = require("src.systems.menu")

    menu = MenuSys.Menu.new{
        title = "PAUSED",
        style = "spikes",  -- optional: "plain" or "spikes"
        options = {
            {txt="Resume", action=function() pause = false end},
            {txt="Main Menu", action=function() Fx.t.cover(function() setScene("menu") end) end},
            {txt="Quit", action=function() love.event.quit() end},
        }
    }

    menuStack = MenuSys.Stack.new(menu)  -- wrap in a stack


    monoShader = love.graphics.newShader("assets/shaders/pause.glsl")
    monoShader:send("levels", 128)
    monoShader:send("strength", 0.9)
end

function Scene.exit()
    gameData = nil
    Fx.debug.remove("Player")

    for _, eff in pairs(loadedImages) do
        Fx.r.unloadImage(eff, path)
    end
    --collectgarbage()
end

function Scene.update(dt)
    if GameState.player.dead then
        if not deathPause then
            table.remove(menu.options, 1)
            menu.title = "YOU DIED" 
            deathPause = true
        end
        pause = true
    end
    if pause then
        if Fx.i.pressed("cancel") then pause = false end
        menuStack:input()
        menuStack:update(dt)
    else
        statPerp()

        local lastX = GameState.player.pos.x
        local lastY = GameState.player.pos.y
        local lastZ = GameState.player.pos.z
        
        local isSubmerged = GameState.player.pos.z < 0
        local mx, my = 0, 0

        if Fx.i.pressed("debugEffect") then
            gameData.game.effectUI.Data.visible = not gameData.game.effectUI.Data.visible
        end
        
        if gameData.game.effectUI.Data.visible then
            gameData.game.effectUI.keypressed(GameState.player)
        else
            if Fx.i.pressed("jump") then
                if GameState.player.jump.cons < GameState.player.stat.jump.lim then
                    GameState.player.jump.cons = GameState.player.jump.cons + 1
                    GameState.player.vel.z = GameState.player.stat.jump.vel
                    GameState.player.jump.timer = GameState.player.stat.jump.cd
                    GameState.player.visual.sx = 0.7 -- Thin
                    GameState.player.visual.sy = 1.4 -- Tall
                    if GameState.player.grounded then
                        gameData.systems.particles.spawnDust(
                            GameState.player.pos.x + 10,
                            GameState.player.pos.y,
                            GameState.player.pos.z,
                            GameState.player.vel.x, 
                            GameState.player.vel.y
                        )
                    end
                end
            end
            if not GameState.player.dead then
                if Fx.i.down("right") then mx = mx + 1 end
                if Fx.i.down("left") then mx = mx - 1 end
                if Fx.i.down("up") then my = my - 1 end
                if Fx.i.down("down") then my = my + 1 end
                if Fx.i.pressed("cancel") then pause = true; menu:resetAnimation() end
            end
        end

        local targetVX = mx * GameState.player.stat.move.maxVel
        local targetVY = my * GameState.player.stat.move.maxVel

        local accel = GameState.player.stat.move.accel
        local decel = GameState.player.stat.move.fri

        -- X axis
        if targetVX ~= 0 then
            GameState.player.vel.x = Fx.m.approach(GameState.player.vel.x, targetVX, accel * dt)
        else
            GameState.player.vel.x = Fx.m.approach(GameState.player.vel.x, 0, decel * dt)
        end

        -- Y axis
        if targetVY ~= 0 then
            GameState.player.vel.y = Fx.m.approach(GameState.player.vel.y, targetVY, accel * dt)
        else
            GameState.player.vel.y = Fx.m.approach(GameState.player.vel.y, 0, decel * dt)
        end

        -- Clamp max speed
        local speed = math.sqrt(GameState.player.vel.x^2 + GameState.player.vel.y^2)
        if speed > GameState.player.stat.move.maxVel then
            local s = GameState.player.stat.move.maxVel / speed
            GameState.player.vel.x = GameState.player.vel.x * s
            GameState.player.vel.y = GameState.player.vel.y * s
        end

        -- Apply X movement
        local nextX = GameState.player.pos.x + GameState.player.vel.x * dt
        local hb = Fx.cl.getPlayerHitbox()
        hb.x = nextX + GameState.player.stat.body.hitbox.xt
        GameState.player.pos.x = nextX

        -- Apply Y movement
        local nextY = GameState.player.pos.y + GameState.player.vel.y * dt
        hb = Fx.cl.getPlayerHitbox()
        hb.y = nextY + GameState.player.stat.body.hitbox.yt
        GameState.player.pos.y = nextY

        -- Z physics
        GameState.player.vel.z = GameState.player.vel.z - GameState.player.stat.jump.g * dt
        GameState.player.pos.z = GameState.player.pos.z + GameState.player.vel.z * dt

        -- Ground resolution
        local hb = Fx.cl.getPlayerHitbox()
        local touchingGround = false

        for _, g in ipairs(GameState.area.ground) do
            if Fx.m.aabb(hb, Fx.cl.getGroundHitbox(g)) then
                touchingGround = true
                break
            end
        end

        if touchingGround and GameState.player.pos.z <= 0 then
            if GameState.player.vel.z < -50 then
                gameData.systems.particles.spawnLandingDust(
                    GameState.player.pos.x + 10,
                    GameState.player.pos.y,
                    0
                )

                GameState.player.visual.sx = 1.5 -- Wide
                GameState.player.visual.sy = 0.5 -- Short
            end

            GameState.player.pos.z = 0
            GameState.player.vel.z = 0
            GameState.player.jump.cons = 0
        end

        local hb = Fx.cl.getPlayerHitbox()
        GameState.player.grounded = touchingGround and GameState.player.vel.z == 0
        local core = getActiveCore(hb)

        if core and GameState.player.grounded and #GameState.player.coinChain > 0 then
            GameState.player.coreProgress =
                math.min(DEPOSIT_TIME, GameState.player.coreProgress + dt)

            if GameState.player.coreProgress >= DEPOSIT_TIME then
                GameState.player.coreProgress = 0

                -- Deposit ONE coin
                table.remove(GameState.player.coinChain, 1)
                GameState.player.coins = GameState.player.coins + 1
                gameData.game.effectSys.remove(GameState.player, "coin", 1)
                if #GameState.area.coins == 0 and #GameState.player.coinChain == 0 then
                    Fx.t.cover(function() setScene("shop") end)
                end
            end
        else
            -- Decay progress
            GameState.player.coreProgress =
                math.max(0, GameState.player.coreProgress - dt * (DEPOSIT_TIME / DECAY_TIME))
        end


        -- Collect coins
        for i, c in ipairs(GameState.area.coins) do
            if Fx.m.aabb(Fx.cl.getPlayerHitbox(), {x=c.x, y=c.y-3, w=10, h=6}) and GameState.player.pos.z < 16 then
                local SPACING = 10

                local coin = {
                    x = c.x,
                    y = c.y,
                    z = GameState.player.pos.z,
                    spacing = SPACING --* (#GameState.player.coinChain + 1)
                }

                table.insert(GameState.player.coinChain, coin)
                table.remove(GameState.area.coins, i)
                gameData.game.effectSys.apply(GameState.player, gameData.game.effects["coin"])
            end
        end

        -- Visual recovery (bring scale back to 1)
        GameState.player.visual.sx = Fx.m.approach(GameState.player.visual.sx, 1, 2 * dt)
        GameState.player.visual.sy = Fx.m.approach(GameState.player.visual.sy, 1, 2 * dt)

        -- Trail
        for i, coin in ipairs(GameState.player.coinChain) do
            local tx, ty, tz

            if i == 1 then
                tx = GameState.player.pos.x
                ty = GameState.player.pos.y
                tz = GameState.player.pos.z + 4
            else
                local prev = GameState.player.coinChain[i - 1]
                tx = prev.x
                ty = prev.y
                tz = prev.z
            end

            followTarget(coin, tx, ty, tz, dt)
        end

        -- Camera
        local camTargetX = GameState.player.pos.x + GameState.player.stat.body.w / 2
        local camTargetY = GameState.player.pos.y + GameState.player.stat.body.h / 2

        gameData.systems.camera.update(camTargetX, camTargetY, dt)

        -- Tails Math
        local speed = math.sqrt(
            GameState.player.vel.x^2 +
            GameState.player.vel.y^2
        )

        gameData.systems.tail.updateTail(
            GameState.player.tail,
            GameState.player.pos.x + GameState.player.base.body.w / 2,
            GameState.player.pos.y - GameState.player.pos.z - 6,
            dt
        )

        gameData.systems.tail.applyTailWave(GameState.player.tail, speed, love.timer.getTime())

        -- Updaters / Handlers
        gameData.systems.particles.updateParticles(dt)
        damageHandler(dt)
        gameData.render.ui.update(dt)
    end
end

function Scene.draw()
    if pause then
        love.graphics.setShader(monoShader)
    end

    gameData.systems.camera.push("world", true)

    -- ## BASE DRAW PART ##

    gameData.render.player.render() -- render player + shadow

    gameData.render.world.renderGround() -- render ground
    gameData.render.world.renderCoins() -- render coins
    gameData.render.world.renderCores() -- render cores

    -- Dust
    gameData.systems.particles.draw()

    -- ## END OF DRAW ##

    Fx.dq.draw() -- draw items in order


    if debug then
        for _, g in ipairs(GameState.area.ground) do
            local gh = Fx.cl.getGroundHitbox(g)
            Fx.r.rect(gh.x, gh.y, gh.w, gh.h, {0,255,255}, false)
        end

        local hb = Fx.cl.getPlayerHitbox()
        Fx.r.rect(hb.x, hb.y, hb.w, hb.h, {255,0,0}, false)

        for _, c in ipairs(GameState.area.cores) do
            Fx.r.rect(c.x, c.y, c.w, c.h, {0,255,0}, false)
        end

        for _, c in ipairs(GameState.area.coins) do
            local ch = {x=c.x, y=c.y-3, w=10, h=6}
            Fx.r.rect(ch.x, ch.y, ch.w, ch.h, {255,255,127}, false)
        end

        for i, s in ipairs(GameState.player.tail) do
            Fx.r.rect(s.x - 1, s.y - 1, 2, 2, {255, 0, 0})
        end
    end

    gameData.systems.camera.pop()

    -- ## USER INERTFACE ##

    gameData.systems.camera.push("ui", false)

    gameData.render.ui.draw()

    gameData.game.effectUI.draw(GameState.player)

    if pause then
        love.graphics.setShader()
        --Fx.r.rect(0,0,Game.width,Game.height,{0,0,0,90})
        menuStack:draw()
    end

    gameData.systems.camera.pop()

    -- ## END OF UI ##
end

return Scene
