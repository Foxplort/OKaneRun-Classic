local Scene = {}

-- ################# --
-- ### VARIABLES ### --
-- ################# --

local EffectSystem = require("src.game.effectSystem")
local Effects      = require("src.game.effects")

-- layout

local PANEL_W = 240
local LINE_W  = 2

-- state

local speakOptions = {}
local buyOptions   = {}
local bought       = {}

local appliedDebuff = nil

local MenuSys = require("src.systems.menu")
local Menu    = MenuSys.Menu
local Stack   = MenuSys.Stack

-- ################# --
-- ### FUNCTIONS ### --
-- ################# --

local function speakMenu()
    return Menu.new{
        title = "Merchant",
        dialogue = speakOptions[love.math.random(#speakOptions)],
        options = {
            { txt = "Back", pop = true }
        }
    }
end

local function buyMenu()
    local opts = {}

    for _, o in ipairs(buyOptions) do
        opts[#opts+1] = {
            txt = o.def.id.." - "..o.price.."c",
            desc = o.def.desc,
            disabled = bought[o.def.id],
            action = function()
                local p = GameState.player
                if p.coins < o.price then return end
                if EffectSystem.apply(p, o.def) then
                    p.coins = p.coins - o.price
                    bought[o.def.id] = true
                end
            end
        }
    end

    opts[#opts+1] = { txt = "Back", pop = true }
    return Menu.new{ title = "Buy", options = opts }
end

menuStack = Stack.new(
    Menu.new{
        title = "Shop",
        options = {
            { txt="Speak", desc="Talk to the merchant.", push = speakMenu },
            { txt="Buy", desc="Purchase items.", push = buyMenu },
            { txt="Leave", action = function() Fx.t.cover(function() setScene("game") end) end }
        }
    }
)

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = love.math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

local function pickRandom(list, n)
    local t = {}
    for _, v in pairs(list) do t[#t+1] = v end
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

-- ######################### --
-- ### MENU CONSTRUCTORS ### --
-- ######################### --

local function buildRootMenu()
    return Menu.new{
        title = "Shop",
        options = {
            { txt = "Speak", desc = "lol", action = function()
                view = "speak"
                menuSub = buildSpeakMenu()
            end },
            { txt = "Buy", action = function()
                view = "buy"
                menuSub = buildBuyMenu()
            end },
            { txt = "Leave", action = function()
                lockInput = true
                message = "See you next time!"
                Fx.t.cover(function()
                    setScene("game")
                end)
            end },
        }
    }
end

function buildSpeakMenu()
    local text = speakOptions[love.math.random(#speakOptions)]

    return Menu.new{
        title = "Merchant",
        dialogue = text,
        options = {
            {
                txt = "Back",
                action = function()
                    view = "root"
                    menuSub = nil
                end
            }
        }
    }
end

function buildBuyMenu()
    local opts = {}

    for _, o in ipairs(buyOptions) do
        local id = o.def.id
        local owned = bought[id]

        opts[#opts+1] = {
            txt = id .. " - " .. o.price .. "c",
            disabled = owned,
            desc = o.def.desc,
            action = function()
                local p = GameState.player
                if p.coins < o.price then return end

                if EffectSystem.apply(p, o.def) then
                    p.coins = p.coins - o.price
                    bought[id] = true
                    menuSub = buildBuyMenu()
                end
            end
        }
    end

    opts[#opts+1] = {
        txt = "Back",
        action = function()
            view = "root"
        end
    }

    return Menu.new{ title = "Buy", options = opts }
end

-- ###################### --
-- ### MAIN FUNCTIONS ### --
-- ###################### --

function Scene.enter()
    view, selection, lockInput = "root", 1, false
    slideX, mainAlpha = 0, 1
    message = nil
    bought  = {}

    local player = GameState.player

    local debuffs = allByType("debuff")
    appliedDebuff = pickRandom(debuffs, 1)[1]
    EffectSystem.apply(player, appliedDebuff)

    speakOptions = {
        "Something is wrong?",
        "I am waiting for you to do your job.",
        "You look tired."
    }
    shuffle(speakOptions)

    buyOptions = {}
    for _, b in ipairs(pickRandom(allByType("buff"), 3)) do
        buyOptions[#buyOptions+1] = {
            def = b,
            price = love.math.random(1, 3)
        }
    end

    menuMain = buildRootMenu()
    menuSub  = nil
end

function Scene.update(dt)
    menuStack:input()
    menuStack:update(dt)
end

function Scene.draw()
    Fx.r.rect(PANEL_W, 0, Game.width-PANEL_W, Game.height, {8,15,20})
    menuStack:draw()

    Fx.r.text( "Cursed: " .. appliedDebuff.id, Game.width - 220, 20, 1, {255, 80, 80}, 200, "right" )
    Fx.r.text( "Money: " .. GameState.player.coins, Game.width - 220, 32, 1, {255, 255, 80}, 200, "right" )
end


return Scene
