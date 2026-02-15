local Scene = {}

local EffectSystem = require("src.game.effectSystem")
local Effects = require("src.game.effects")

-- ======================
-- CONFIG
-- ======================

local PANEL_Y = Game.height * 0.45
local OPTION_Y = PANEL_Y + 40
local LINE_H = 28

-- ======================
-- STATE
-- ======================

local view = "root" -- root / speak / buy
local selection = 1
local lockInput = false
local message = nil

local speakOptions = {}
local buyOptions = {}
local bought = {}

local appliedDebuff = nil

-- ======================
-- UTILS
-- ======================

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = love.math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

local function pickRandom(list, n)
    local t = {}
    for k, v in pairs(list) do t[#t+1] = v end
    shuffle(t)
    local r = {}
    for i = 1, math.min(n, #t) do r[#r+1] = t[i] end
    return r
end

local function allByType(t)
    local r = {}
    for _, e in pairs(Effects) do
        if e.type == t then r[#r+1] = e end
    end
    return r
end

-- ======================
-- ENTER
-- ======================

function Scene.enter()
    selection = 1
    view = "root"
    lockInput = false
    message = nil
    bought = {}

    local player = GameState.player

    -- Apply RANDOM DEBUFF
    local debuffs = allByType("debuff")
    appliedDebuff = pickRandom(debuffs, 1)[1]
    EffectSystem.apply(player, appliedDebuff)

    -- SPEAK OPTIONS
    speakOptions = {
        "It's dangerous out there.",
        "Everything has a price.",
        "You look tired."
    }
    shuffle(speakOptions)

    -- BUY OPTIONS
    local buffs = pickRandom(allByType("buff"), 3)
    buyOptions = {}

    for _, b in ipairs(buffs) do
        buyOptions[#buyOptions+1] = {
            def = b,
            price = love.math.random(1, 3)
        }
    end
end

-- ======================
-- INPUT
-- ======================

local function currentOptions()
    if view == "root" then
        return {
            { txt = "Speak", action = function() view = "speak"; selection = 1 end },
            { txt = "Buy",   action = function() view = "buy";   selection = 1 end },
            { txt = "Leave", action = function()
                lockInput = true
                message = "See you next time!"
                Fx.t.cover(function()
                    setScene("game")
                end)
            end },
        }
    elseif view == "speak" then
        local t = {}
        for _, s in ipairs(speakOptions) do
            t[#t+1] = { txt = s, isLabel = true }
        end
        t[#t+1] = { txt = "Back", action = function() view = "root"; selection = 1 end }
        return t
    elseif view == "buy" then
        local t = {}
        for _, o in ipairs(buyOptions) do
            local id = o.def.id
            local owned = bought[id]

            t[#t+1] = {
                txt = o.def.id .. " - " .. o.price .. "c",
                disabled = owned,
                desc = o.def.desc,
                action = function()
                    local p = GameState.player
                    if p.coins < o.price then return end

                    if EffectSystem.apply(p, o.def) then
                        p.coins = p.coins - o.price
                        bought[id] = true
                    end
                end
            }
        end
        t[#t+1] = { txt = "Back", action = function() view = "root"; selection = 1 end }
        return t
    end
end

local function keypressed()
    if lockInput then return end

    local opts = currentOptions()

    if Fx.i.pressed("up") then
        selection = (selection - 2) % #opts + 1
    elseif Fx.i.pressed("down") then
        selection = selection % #opts + 1
    elseif Fx.i.pressed("cancel") then
        if view ~= "root" then view = "root"; selection = 1 end
    elseif Fx.i.pressed("accept") then
        local o = opts[selection]
        if o and o.action and not o.disabled then
            o.action()
        end
    end
end

-- ======================
-- UPDATE
-- ======================

function Scene.update(dt)
    keypressed()
end

-- ======================
-- DRAW
-- ======================

function Scene.draw()
    -- BACKGROUND
    Fx.r.rect(0, 0, Game.width, Game.height, {10, 14, 18})

    -- TOP (ART PLACEHOLDER)
    Fx.r.text("???", Game.width/2, 80, 3, {80, 80, 80}, nil, "center")

    -- DEBUFF DISPLAY (TOP RIGHT)
    Fx.r.text(
        "Cursed: " .. appliedDebuff.id,
        Game.width - 20,
        20,
        1,
        {255, 80, 80},
        nil,
        "right"
    )

    -- SHOP PANEL
    Fx.r.rect(0, PANEL_Y, Game.width, Game.height - PANEL_Y, {0, 0, 0, 200})

    local opts = currentOptions()

    for i, o in ipairs(opts) do
        local y = OPTION_Y + (i-1) * LINE_H
        local col = {200, 200, 200}

        if i == selection then col = {255, 255, 255} end
        if o.disabled then col = {90, 90, 90} end
        if o.isLabel then col = {160, 160, 120} end

        Fx.r.text(o.txt, 40, y, 1, col)
    end

    -- MESSAGE
    if message then
        Fx.r.text(message, Game.width/2, Game.height - 40, 1.5, {255,255,255}, nil, "center")
    end
end

return Scene
