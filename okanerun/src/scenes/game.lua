local Scene = {}

-- ################# --
-- ### VARIABLES ### --
-- ################# --

local gameData = nil
local loadedImages = {}
local pause = false
local pauseLockout = 0
local deathPause = false
local menu = nil
local exit_submenu = nil
local back_to_menu_submenu = nil
local menuStack = nil
local monoShader = nil

local DEPOSIT_TIME = 0.8
local DECAY_TIME = 2

local jumpQueue = {}

-- ######################## --
-- ### HELPER FUNCTIONS ### --
-- ######################## --

local function followTarget(coin, tx, ty, tz, dt)
    local dx = coin.x - tx
    local dy = coin.y - ty
    local dz = coin.z - tz

    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
    if dist < 0.1 then return end

    local spacing = coin.spacing
    if dist > spacing then
        -- Instead of a fixed pull velocity, we move towards the "ideal" point
        -- which is at 'spacing' distance from the target.
        local ratio = spacing / dist
        local targetX = tx + dx * ratio
        local targetY = ty + dy * ratio
        
        -- Framerate-independent exponential decay
        local xySmooth = 1 - math.exp(-15 * dt)
        coin.x = fore.math.lerp(coin.x, targetX, xySmooth)
        coin.y = fore.math.lerp(coin.y, targetY, xySmooth)
    end
    
    -- Z follow (framerate-independent exponential decay)
    local zSmooth = 1 - math.exp(-12 * dt)
    coin.z = fore.math.lerp(coin.z, tz, zSmooth)
end

local function checkPB()
    local pb = fore.save.get("personal_best")
    if GameState.score > pb then
        fore.save.set("personal_best", GameState.score)
    end
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
    if not GameState.player.effectsChanged then return end
    GameState.player.stat = applyMods(GameState.player.base, GameState.player.mod)
    local d = GameState.player.dash
    d.power = d.flat + (GameState.player.stat.move.maxVel * d.mult)
end

local function getActiveCore(hb)
    for _, c in ipairs(GameState.area.cores) do
        local zone = { x = c.x, y = c.y, w = c.w, h = c.h }
        if fore.math.aabb(hb, zone) then
            return c
        end
    end
    return nil
end



local function queueJump(delay, mul)
    table.insert(jumpQueue, {time = delay, mul = mul or 1})
end

-- ######################### --
-- ### SUBMAIN FUNCTIONS ### --
-- ######################### --

local invTime = 0
local function damagePlayer(amount, timeMod, source)
    if invTime <= 0 then
        local p = GameState.player

        if p.dead then return end

        amount = amount or 1
        local voided = 0

        if GameState.player.effectRef.chance then
            if math.random() < 0.2 * GameState.player.effectRef.chance then
                amount = 0
                voided = GameState.player.effectRef.chance
            end
        end

        p.hp.count = p.hp.count - amount
        p.lastDamageSource = source

        -- camera feedback
        fore.camera.addShake("world", 3)
        fore.camera.addShake("ui", 3)

        if p.hp.count <= 0 then
            fore.save.set("deaths", fore.save.get("deaths") + 1)
            p.dead = true
        end

        invTime = 1.2
        if timeMod then invTime = invTime * timeMod end
        if GameState.player.effectRef.bloodloss then
            invTime = invTime * (0.6^GameState.player.effectRef.bloodloss) * (0.8^voided)
        end
    end
end

local function damageHandler(dt)
    -- Fall into the pit
    if GameState.player.pos.z <= -150 then
        damagePlayer(1, 1, "pit")

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

        -- Reset Z history so coins don't replay the teleport
        GameState.player.zHistory = {{z = GameState.player.pos.z, t = 0}}
    end
end

-- ###################### --
-- ### MAIN FUNCTIONS ### --
-- ###################### --

function Scene.enter()
    -- LOAD THE LEVEL
    local levelList = require("okanerun.src.data.levels")
    
    if fore.editor and fore.editor.playCustom then
        local target = "custom.4lf"
        if love.filesystem.getInfo("play_queue.txt") then
            target = love.filesystem.read("play_queue.txt")
            love.filesystem.remove("play_queue.txt")
        end
        
        if love.filesystem.getInfo("levels/" .. target) then
            GameState.area = Fx.ll.load("levels/" .. target)
        else
            GameState.area = Fx.ll.load("okanerun/src/data/levels/" .. levelList[math.random(#levelList)] .. ".4lf")
        end
        fore.editor.playCustom = false
    else
        GameState.area = Fx.ll.load("okanerun/src/data/levels/" .. levelList[math.random(#levelList)] .. ".4lf")
    end

    --GameState.area = Fx.ll.load("okanerun/src/data/levels/dotedPath.json")


    -- RESET VARIABLES
    pause = false
    deathPause = false
    GameState.player.pos.x = GameState.area.spawn.x - GameState.player.base.body.hitbox.w/2
    GameState.player.pos.y = GameState.area.spawn.y - GameState.player.base.body.hitbox.h/2
    GameState.player.pos.z = 40
    GameState.player.coinChain = {}
    GameState.player.damage = damagePlayer
    GameState.player.afterimages = {}
    GameState.player.effectsChanged = true
    GameState.player.zHistory = {{z = 40, t = 0}}

    statPerp()

    gameData = {
        render = {
            player = require("okanerun.src.render.player"),
            world = require("okanerun.src.render.world"),
            ui = require("okanerun.src.render.ui" .. ((fore.data.phone or mobileUiStatus) and "Phone" or "")),
        },
        systems = {
            tail = require("okanerun.src.systems.playerTail"),
            particles = require("okanerun.src.systems.particles"),
        },
        game = {
            effects = require("okanerun.src.game.effects"),
            effectSys = require("okanerun.src.game.effectSystem"),
            effectUI = require("okanerun.src.game.effectUI"),
        },
    }

    fore.camera.init(GameState.area.mapWidth, GameState.area.mapHeight)
    fore.camera.setPosition(
        GameState.player.pos.x + GameState.player.stat.body.w / 2,
        GameState.player.pos.y + GameState.player.stat.body.h / 2,
        true
    )
    gameData.game.effectUI.load(gameData.game.effects, gameData.game.effectSys)
    gameData.systems.particles.reset()
    gameData.render.ui.resetIntro()

    fore.assets.scheduleLoad("missing", "okanerun/assets/images/buffs/missing.png")
    for id, eff in pairs(gameData.game.effects) do
        local path = "okanerun/assets/images/buffs/" .. eff.id .. ".png"
        if love.filesystem.getInfo(path) then
            fore.assets.scheduleLoad(eff.id, path)
            table.insert(loadedImages, eff.id)
        end
    end
    fore.assets.scheduleLoad("icon_exit", "okanerun/assets/images/ui/menu/exit.png", "linear")
    fore.assets.scheduleLoad("icon_back", "okanerun/assets/images/ui/menu/back.png", "linear")
    fore.assets.scheduleLoad("icon_play", "okanerun/assets/images/ui/menu/play.png", "linear")

    -- LOAD PLAYER ASSETS
    local playerAssets = {"1", "2", "3", "4", "5", "6"}
    for _, name in ipairs(playerAssets) do
        local path = "okanerun/assets/images/player/" .. name .. ".png"
        fore.assets.scheduleLoad(name, path)
        table.insert(loadedImages, name)
    end

    fore.debug.add("Player", function()
        local p = GameState.player
        return {
            string.format("pos: %.1f / %.1f", p.pos.x, p.pos.y),
            string.format("z: %.1f  vz: %.2f", p.pos.z or 0, p.vel.z or 0),
            "grounded: " .. tostring(p.grounded),
            "coins: " .. p.coins
        }
    end)

    local MenuSys = require("okanerun.src.systems.menu")

    exit_submenu = MenuSys.Menu:new{
        title = "QUIT?",
        style = "spikes",
        outline = true,
        options = {
            {
                txt = "Confirm", action = function() love.event.quit() end, icon = "icon_exit",
                desc = [[
                Are you sure you want to quit?
                The progress won't be saved.[br]
                ]]
            },
            { txt = "Cancel", pop = true, icon = "icon_back" }
        }
    }

    back_to_menu_submenu = MenuSys.Menu:new{
        title = "RETURN?",
        style = "spikes",
        outline = true,
        options = {
            {
                txt = "Confirm", action=function() fore.transition.start("spike", function() fore.scenes:goTo("menu") end, nil, 0, 0.6) end, icon = "icon_exit",
                desc = [[
                Are you sure you want to return to the main menu?
                The progress won't be saved.[br]
                ]]
            },
            { txt = "Cancel", pop = true, icon = "icon_back" }
        }
    }

    menu = MenuSys.Menu:new{
        title = "PAUSED",
        style = "spikes",  -- optional: "plain" or "spikes"
        outline = true,
        options = {
            {txt="Resume", icon="icon_play", action=function() pause = false; fore.mobileControls:show() end},
            {txt="Main Menu", icon="icon_back", push = function() return back_to_menu_submenu end},
            {txt="Quit", icon="icon_exit", push = function() return exit_submenu end},
        }
    }

    menuStack = MenuSys.Stack.new(menu)  -- wrap in a stack


    monoShader = fore.shader.new("okanerun/assets/shaders/pause.glsl")
    monoShader:send("levels", 128)
    monoShader:send("strength", 0.9)

    fore.audio.load("footsteps", "okanerun/assets/sounds/game/footstep.wav", false, "sfx")
    fore.audio.load("coin_pickup", "okanerun/assets/sounds/game/coin.ogg", false, "sfx")
    fore.audio.load("coin_deposit", "okanerun/assets/sounds/game/deposit.ogg", false, "sfx")
    fore.audio.load("jump", "okanerun/assets/sounds/game/jump.ogg", false, "sfx")

    for _, entry in pairs(GameState.player.effects) do
        if entry.def.onReset then
            for _, inst in ipairs(entry.instances) do
                entry.def.onReset(GameState.player, inst)
            end
        end
    end

    fore.mobileControls:show()
    pauseLockout = 0
end

function Scene.exit()
    fore.mobileControls:hide()
    gameData = nil
    fore.debug.remove("Player")

    for _, eff in pairs(loadedImages) do
        fore.assets.scheduleUnload(eff)
    end
    fore.assets.scheduleUnload("missing")
    fore.assets.scheduleUnload("icon_exit")
    fore.assets.scheduleUnload("icon_back")
    fore.assets.scheduleUnload("icon_play")

    fore.audio.unload("footsteps")
    fore.audio.unload("coin_pickup")
    fore.audio.unload("coin_deposit")
    fore.audio.unload("jump")
    fore.save.write()
end

function Scene.update(dt)
    if GameState.player.dead then
        if not deathPause then
            deathPause = true
            fore.audio.stopCategory("music")
            fore.audio.stopCategory("sfx")
            fore.audio.play("coin_pickup", {
                pitch = 0.08,
                volume = 0.09
            })
            fore.audio.play("coin_pickup", {
                pitch = 0.5,
                volume = 0.05
            })
            fore.audio.play("coin_pickup", {
                pitch = 0.3,
                volume = 0.07
            })
            fore.transition.start("dither", function()
                fore.task.delay(2.5, function()
                    fore.scenes:goTo("death")
                end)
            end, nil, 0, 1.2, false)
        end
        return
    end
    if pause then
        pauseLockout = math.max(0, pauseLockout - dt)
        if pauseLockout <= 0 then
            if fore.input:pressed("pause") or fore.input:pressed("cancel") then 
                pause = false 
                fore.mobileControls:show()
            end
            menuStack:input()
        end
        menuStack:update(dt)
    else
        statPerp()

        local lastX = GameState.player.pos.x
        local lastY = GameState.player.pos.y
        local lastZ = GameState.player.pos.z
        
        -- Record Z History for coin follow
        -- Age existing entries
        for _, entry in ipairs(GameState.player.zHistory) do
            entry.t = entry.t + dt
        end
        -- Insert current Z at the front (newest = index 1, age 0)
        table.insert(GameState.player.zHistory, 1, {z = GameState.player.pos.z, t = 0})
        -- Trim entries older than 10 seconds
        local MAX_HISTORY_TIME = 10
        while #GameState.player.zHistory > 1 and GameState.player.zHistory[#GameState.player.zHistory].t > MAX_HISTORY_TIME do
            table.remove(GameState.player.zHistory)
        end
        
        local isSubmerged = GameState.player.pos.z < 0
        local mx, my = 0, 0

        if fore.input:pressed("debugEffect") and fore.data.devmode then
            gameData.game.effectUI.Data.visible = not gameData.game.effectUI.Data.visible
        end

        if gameData.game.effectUI.Data.visible then
            gameData.game.effectUI.keypressed(GameState.player)
        else
            local chargeActive = GameState.player.effects["charged"]
            if not chargeActive then
                if fore.input:pressed("jump") then
                    if not GameState.player.effectRef.sticky or GameState.player.effectRef.sticky <= 0 then
                        queueJump(0)
                    else
                        queueJump(0.1 * GameState.player.effectRef.sticky)
                    end
                end
            else
                if not GameState.player.dead then
                    if fore.input:down("jump") then
                        GameState.player.effectRef.charged = GameState.player.effectRef.charged + dt
                        if GameState.player.effectRef.charged >= 2 then
                            local mul = 0.7 + (math.min(GameState.player.effectRef.charged, 0.8) / 0.8) * 0.6
                            local delay = 0
                            if GameState.player.effectRef.sticky and GameState.player.effectRef.sticky > 0 then
                                delay = 0.15 * GameState.player.effectRef.sticky
                            end
                            queueJump(delay, mul)
                            GameState.player.effectRef.charged = 0
                        end
                    elseif GameState.player.effectRef.charged > 0 then
                        -- Released
                        local mul = 0.7 + (math.min(GameState.player.effectRef.charged, 0.8) / 0.8) * 0.6
                        local delay = 0
                        if GameState.player.effectRef.sticky and GameState.player.effectRef.sticky > 0 then
                            delay = 0.15 * GameState.player.effectRef.sticky
                        end
                        queueJump(delay, mul)
                        GameState.player.effectRef.charged = 0
                    end
                else
                    GameState.player.effectRef.charged = 0
                end
            end

            for i = #jumpQueue, 1, -1 do
                local j = jumpQueue[i]
                j.time = j.time - dt

                if j.time <= 0 then
                    if GameState.player.jump.cons < GameState.player.stat.jump.lim then
                        GameState.player.jump.cons = GameState.player.jump.cons + 1
                        GameState.player.vel.z = GameState.player.stat.jump.vel * j.mul
                        GameState.player.jump.timer = GameState.player.stat.jump.cd

                        GameState.player.visual.sx = 0.7
                        GameState.player.visual.sy = 1.4
                        GameState.player.anim.jumpTimer = 0.12

                        if GameState.player.grounded then
                            gameData.systems.particles.spawnDust(
                                GameState.player.pos.x + 10,
                                GameState.player.pos.y,
                                GameState.player.pos.z,
                                GameState.player.vel.x, 
                                GameState.player.vel.y
                            )

                            fore.audio.play("footsteps", {
                                pitch = math.random(35, 65) / 100,
                                volume = 0.1
                            })
                        end

                        fore.audio.play("jump", {
                            pitch = math.random(145, 185) / 100,
                            volume = 0.2
                        })

                        table.remove(jumpQueue, i)
                    elseif j.time <= -0.1 then
                        table.remove(jumpQueue, i)
                    end
                end
            end

            if not GameState.player.dead then
                if fore.input:down("right") then mx = mx + 1 end
                if fore.input:down("left") then mx = mx - 1 end
                if fore.input:down("up") then my = my - 1 end
                if fore.input:down("down") then my = my + 1 end
                if fore.input:pressed("pause") then 
                    pause = true
                    pauseLockout = 0.2
                    fore.mobileControls:hide()
                    menu:resetAnimation() 
                end
                if GameState.player.effectRef.confused then
                    mx = -mx
                    my = -my
                end
            end
        end

        if GameState.player.dash.timer <= 0 then
            local targetVX = mx * GameState.player.stat.move.maxVel
            local targetVY = my * GameState.player.stat.move.maxVel

            local accel = GameState.player.stat.move.accel
            local decel = GameState.player.stat.move.fri

            local w = GameState.player.effectRef.windy
            if w then
                w.timer = w.timer - dt

                if w.timer <= 0 then
                    w.dir = math.random() * math.pi * 2
                    w.targetStrength = math.random(20, 70)
                    w.timer = math.random(1.5, 3)
                end

                w.strength = fore.math.approach(w.strength, w.targetStrength, 60 * dt)

                local fx = math.cos(w.dir) * w.strength
                local fy = math.sin(w.dir) * w.strength

                targetVX = targetVX + fx
                targetVY = targetVY + fy
            end

            -- X axis
            if targetVX ~= 0 then
                GameState.player.vel.x = fore.math.approach(GameState.player.vel.x, targetVX, accel * dt)
            else
                GameState.player.vel.x = fore.math.approach(GameState.player.vel.x, 0, decel * dt)
            end

            -- Y axis
            if targetVY ~= 0 then
                GameState.player.vel.y = fore.math.approach(GameState.player.vel.y, targetVY, accel * dt)
            else
                GameState.player.vel.y = fore.math.approach(GameState.player.vel.y, 0, decel * dt)
            end

            -- Clamp max speed
            local speed = math.sqrt(GameState.player.vel.x^2 + GameState.player.vel.y^2)
            if speed > GameState.player.stat.move.maxVel then
                local s = GameState.player.stat.move.maxVel / speed
                GameState.player.vel.x = GameState.player.vel.x * s
                GameState.player.vel.y = GameState.player.vel.y * s
            end
        else
            local d = GameState.player.dash
            local t = d.timer / d.time
            local speedMul = 0.6 + 0.4 * t

            local inputLen = math.sqrt(mx*mx + my*my)
            if inputLen > 0 then
                mx, my = mx/inputLen, my/inputLen

                -- blend direction
                local steer = 6
                d.dir.x = fore.math.approach(d.dir.x, mx, steer * dt)
                d.dir.y = fore.math.approach(d.dir.y, my, steer * dt)

                -- normalize again
                local len = math.sqrt(d.dir.x^2 + d.dir.y^2)
                if len > 0 then
                    d.dir.x, d.dir.y = d.dir.x/len, d.dir.y/len
                end
            end
            
            GameState.player.vel.x = d.dir.x * d.power * speedMul
            GameState.player.vel.y = d.dir.y * d.power * speedMul
        end

        if fore.input:pressed("dash") and GameState.player.dash.cooldown <= 0 then
            local dx = mx
            local dy = my

            if dx == 0 and dy == 0 then
                dx = GameState.player.vel.x
                dy = GameState.player.vel.y
            end

            local len = math.sqrt(dx*dx + dy*dy)
            if len > 0 then
                GameState.player.visual.sx = 1.6
                GameState.player.visual.sy = 0.6
                dx, dy = dx/len, dy/len

                GameState.player.dash.dir.x = dx
                GameState.player.dash.dir.y = dy
                GameState.player.dash.timer = GameState.player.dash.time
                GameState.player.dash.cooldown = GameState.player.dash.cdMax

                fore.audio.play("jump", {
                    pitch = math.random(145, 185) / 100,
                    volume = 0.2
                })
            end
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

        local GROUND_SNAP = 0        -- normal ground level
        local GROUND_BUFFER = -4     -- "forgiveness" zone
        local GROUND_SOLID = -8      -- becomes wall

        local touchingGround = false
        local blockingGround = false

        for _, g in ipairs(GameState.area.ground) do
            local gh = Fx.cl.getGroundHitbox(g)

            if fore.math.aabb(hb, gh) then
                touchingGround = true

                -- If player is deep below → treat as wall
                if GameState.player.pos.z < GROUND_SOLID then
                    blockingGround = true

                    -- Push player OUT horizontally (like walls)
                    if lastX + GameState.player.stat.body.hitbox.xt + hb.w <= gh.x then
                        GameState.player.pos.x = gh.x - GameState.player.stat.body.hitbox.xt - hb.w
                    elseif lastX + GameState.player.stat.body.hitbox.xt >= gh.x + gh.w then
                        GameState.player.pos.x = gh.x + gh.w - GameState.player.stat.body.hitbox.xt
                    end

                    if lastY + GameState.player.stat.body.hitbox.yt + hb.h <= gh.y then
                        GameState.player.pos.y = gh.y - GameState.player.stat.body.hitbox.yt - hb.h
                    elseif lastY + GameState.player.stat.body.hitbox.yt >= gh.y + gh.h then
                        GameState.player.pos.y = gh.y + gh.h - GameState.player.stat.body.hitbox.yt
                    end
                end

                break
            end
        end

        -- NORMAL GROUND + BUFFER
        if touchingGround and not blockingGround then
            if GameState.player.pos.z <= GROUND_SNAP then
                if GameState.player.vel.z < -50 then
                    gameData.systems.particles.spawnLandingDust(
                        GameState.player.pos.x + 10,
                        GameState.player.pos.y,
                        0
                    )

                    GameState.player.visual.sx = 1.5
                    GameState.player.visual.sy = 0.5
                    GameState.player.anim.landTimer = 0.18
                end

                GameState.player.pos.z = GROUND_SNAP
                GameState.player.vel.z = 0
                GameState.player.jump.cons = 0
            elseif GameState.player.pos.z < GROUND_SNAP and GameState.player.pos.z > GROUND_BUFFER then
                -- soft push up (forgiveness zone)
                GameState.player.pos.z = fore.math.approach(
                    GameState.player.pos.z,
                    GROUND_SNAP,
                    120 * dt
                )
                GameState.player.vel.z = 0
            end
        end

        local hb = Fx.cl.getPlayerHitbox()
        GameState.player.grounded = touchingGround and GameState.player.pos.z == 0
        local core = getActiveCore(hb)

        if core and GameState.player.grounded and #GameState.player.coinChain > 0 then
            GameState.player.coreProgress =
                math.min(DEPOSIT_TIME, GameState.player.coreProgress + dt)

            if GameState.player.coreProgress >= DEPOSIT_TIME then
                GameState.player.coreProgress = 0

                -- Deposit ONE coin
                table.remove(GameState.player.coinChain, 1)
                GameState.player.coins = GameState.player.coins + 1
                GameState.score = GameState.score + 10
                checkPB()

                gameData.game.effectSys.remove(GameState.player, "coin", 1)
                fore.save.set("coins_deposited", fore.save.get("coins_deposited") + 1)
                if #GameState.area.coins == 0 and #GameState.player.coinChain == 0 then
                    GameState.score = GameState.score + 20
                    checkPB()
                    fore.transition.start("dither", function() fore.scenes:goTo("selection") end, nil, 0, 0.6)
                end

                fore.audio.play("coin_deposit", {
                    pitch = math.random(85, 115) / 100,
                    volume = 0.2
                })
            end
        else
            -- Decay progress
            GameState.player.coreProgress =
                math.max(0, GameState.player.coreProgress - dt * (DEPOSIT_TIME / DECAY_TIME))
        end


        local Objects = require("okanerun.src.data.objects")
        -- Collect coins
        for i, c in ipairs(GameState.area.coins) do
            if fore.math.aabb(Fx.cl.getPlayerHitbox(), Objects["coin"].hitbox(c)) and GameState.player.pos.z < 16 then
                local SPACING = 10

                local coin = {
                    x = c.x,
                    y = c.y,
                    z = GameState.player.pos.z,
                    spacing = SPACING
                }

                fore.audio.play("coin_pickup", {
                    pitch = math.random(85, 115) / 100,
                    volume = 0.2
                })

                table.insert(GameState.player.coinChain, coin)
                table.remove(GameState.area.coins, i)
                gameData.game.effectSys.apply(GameState.player, gameData.game.effects["coin"])
            end
        end

        -- ANIMATION & FOOTSTEPS
        local speedVal = math.sqrt(GameState.player.vel.x^2 + GameState.player.vel.y^2)
        local p = GameState.player

        p.anim.jumpTimer = math.max(0, p.anim.jumpTimer - dt)
        p.anim.landTimer = math.max(0, p.anim.landTimer - dt)

        if p.anim.landTimer > 0 then
            p.anim.frame = 5
        elseif p.anim.jumpTimer > 0 then
            p.anim.frame = 5
        elseif p.dash.timer > 0 then
            p.anim.frame = 4
        elseif not p.grounded then
            p.anim.frame = 6
        elseif speedVal > 10 then
            p.anim.state = "walk"
            -- Playback
            p.anim.timer = p.anim.timer + dt * (speedVal / 180)
            local frames = {2, 1, 3, 1}
            local frameIndex = math.floor(p.anim.timer / p.anim.speed) % #frames + 1
            p.anim.frame = frames[frameIndex]

            -- Sync sound with frame index change
            if frameIndex ~= p.anim.lastIdx then
                if frameIndex == 1 or frameIndex == 3 then
                    fore.audio.play("footsteps", {
                        pitch = math.random(45, 65) / 100,
                        volume = 0.1
                    })
                end
                p.anim.lastIdx = frameIndex
            end
        else
            p.anim.state = "idle"
            p.anim.frame = 1
            p.anim.timer = 0
            p.anim.lastIdx = 0
        end

        if p.vel.x > 5 then
            p.anim.flipX = false
        elseif p.vel.x < -5 then
            p.anim.flipX = true
        end


        -- Visual recovery (bring scale back to 1)
        GameState.player.visual.sx = fore.math.approach(GameState.player.visual.sx, 1, 2 * dt)
        GameState.player.visual.sy = fore.math.approach(GameState.player.visual.sy, 1, 2 * dt)

        -- Trail
        for i, coin in ipairs(GameState.player.coinChain) do
            local tx, ty, tz

            if i == 1 then
                tx = GameState.player.pos.x
                ty = GameState.player.pos.y
            else
                local prev = GameState.player.coinChain[i - 1]
                tx = prev.x
                ty = prev.y
            end

            -- Z following with time-based delay
            local Z_DELAY_PER_COIN = 0.1  -- seconds of delay per coin in chain
            local targetTime = i * Z_DELAY_PER_COIN
            local zh = GameState.player.zHistory

            -- Sample Z from history at the target time offset, with interpolation
            tz = zh[#zh].z + 4  -- fallback: oldest entry
            for j = 1, #zh do
                if zh[j].t >= targetTime then
                    if j > 1 then
                        -- Interpolate between the two surrounding entries
                        local a, b = zh[j - 1], zh[j]
                        local frac = (targetTime - a.t) / (b.t - a.t)
                        tz = a.z + (b.z - a.z) * frac + 4
                    else
                        tz = zh[j].z + 4
                    end
                    break
                end
            end

            followTarget(coin, tx, ty, tz, dt)
        end

        -- Camera
        local camTargetX = GameState.player.pos.x + GameState.player.stat.body.w / 2
        local camTargetY = GameState.player.pos.y + GameState.player.stat.body.h / 2

        fore.camera.update(camTargetX, camTargetY, dt)
        fore.camera.setCategoryZoom("world", GameState.player.camZoom, false)

        -- Tails Math
        local speed = math.sqrt(
            GameState.player.vel.x^2 +
            GameState.player.vel.y^2
        )

        gameData.systems.tail.updateTail(
            GameState.player.tail,
            GameState.player.pos.x + GameState.player.base.body.w / 2,
            GameState.player.pos.y - GameState.player.pos.z - 22 + (GameState.player.anim.state == "walk" and (GameState.player.anim.frame == 2 or GameState.player.anim.frame == 3) and 2 or 0),
            dt
        )

        gameData.systems.tail.applyTailWave(GameState.player.tail, speed, fore.time.getTicks(), dt)

        -- Updaters / Handlers
        gameData.systems.particles.updateParticles(dt)
        damageHandler(dt)
        gameData.render.ui.update(dt)
        gameData.game.effectSys.update(GameState.player, dt)
        invTime = invTime - dt
        if invTime > 0 then GameState.player.inv = true else GameState.player.inv = false end

        if GameState.player.dash.cooldown > 0 then
            GameState.player.dash.cooldown = GameState.player.dash.cooldown - dt
        end

        GameState.player.dash.afterimageTimer = (GameState.player.dash.afterimageTimer or 0) - dt

        if GameState.player.dash.timer > 0 then
            GameState.player.dash.timer = GameState.player.dash.timer - dt

            GameState.player.vel.x = GameState.player.dash.dir.x * GameState.player.dash.power
            GameState.player.vel.y = GameState.player.dash.dir.y * GameState.player.dash.power

            if GameState.player.dash.afterimageTimer <= 0 then
                GameState.player.dash.afterimageTimer = 0.05
                table.insert(GameState.player.afterimages, {
                    x = GameState.player.pos.x,
                    y = GameState.player.pos.y,
                    z = GameState.player.pos.z,
                    sx = GameState.player.visual.sx,
                    sy = GameState.player.visual.sy,
                    life = 0.3
                })
            end
        end

        for i = #GameState.player.afterimages, 1, -1 do
            local a = GameState.player.afterimages[i]
            a.life = a.life - dt

            if a.life <= 0 then
                table.remove(GameState.player.afterimages, i)
            end
        end
    end
end

function Scene.draw()
    if pause then
        monoShader:push()
    end

    fore.camera.push("world", true)

    -- ## BASE DRAW PART ##

    gameData.render.player.render() -- render player + shadow

    gameData.render.world.renderGround() -- render ground
    gameData.render.world.renderCoins() -- render coins
    gameData.render.world.renderCores() -- render cores

    -- Dust
    gameData.systems.particles.draw()

    -- Hazards
    for _, entry in pairs(GameState.player.effects) do
        if entry.def.onDraw then
            for _, inst in ipairs(entry.instances) do
                entry.def.onDraw(GameState.player, inst)
            end
        end
    end

    -- ## END OF DRAW ##

    fore.queuer.draw() -- draw items in order


    if fore.debug.enabled and fore.data.devmode then
        for _, g in ipairs(GameState.area.ground) do
            local gh = Fx.cl.getGroundHitbox(g)
            fore.draw2d.rect(gh.x, gh.y, gh.w, gh.h, {0,255,255}, false)
        end

        local hb = Fx.cl.getPlayerHitbox()
        fore.draw2d.rect(hb.x, hb.y, hb.w, hb.h, {255,0,0}, false)

        for _, c in ipairs(GameState.area.cores) do
            fore.draw2d.rect(c.x, c.y, c.w, c.h, {0,255,0}, false)
        end

        for _, c in ipairs(GameState.area.coins) do
            local ch = {x=c.x-13, y=c.y-14, w=26, h=24}
            fore.draw2d.rect(ch.x, ch.y, ch.w, ch.h, {255,255,127}, false)
        end

        for i, s in ipairs(GameState.player.tail) do
            fore.draw2d.rect(s.x - 1, s.y - 1, 2, 2, {255, 0, 0})
        end
    end

    fore.camera.pop()

    -- ## USER INERTFACE ##

    fore.camera.push("ui", false)

    gameData.render.ui.draw()

    gameData.game.effectUI.draw(GameState.player)

    if pause then
        fore.shader.pop()
        --fore.draw2d.rect(0,0,fore.data.width,fore.data.height,{0,0,0,90})
        menuStack:draw()

        local center = (fore.data.width - 220)/2 + 220 -- have to be recalculated every frame since window size can be changed
        local polygonShape = {center - 100, 25, center + 100, 25, center + 120, 50, center + 100, 75, center - 100, 75, center - 120, 50}
        fore.draw2d.polygon(polygonShape, {0,0,0,200}, true)
        fore.draw2d.polygon(polygonShape, {255,255,255,40}, false)
        fore.text.textEx("playing", 220, 30, 1, {255,255,255}, (fore.data.width - 220), "center")
        fore.text.textEx(GameState.area.levelName, 220, 40, 2, {255,255,255}, (fore.data.width - 220), "center")
        fore.text.textEx("by " .. GameState.area.levelAuthor, 220, 60, 1, {255,255,255}, (fore.data.width - 220), "center")
    elseif deathPause then
        fore.draw2d.rect(0,0,fore.data.width,fore.data.height,{0,0,0,255})
    end

    fore.camera.pop()

    -- ## END OF UI ##
end

return Scene
