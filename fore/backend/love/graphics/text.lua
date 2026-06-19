local TextUtil = {}

local fore = nil
local TypeRef = require("fore.backend.love.graphics.types")
local setColor = TypeRef.setColor
local coloring = TypeRef.coloring

TextUtil.base_font_sizes = {
    small = 2,
    medium = 4,
    large = 8
}

TextUtil.fonts = {}

function TextUtil.init(foreRef)
    fore = foreRef
    TextUtil.updateFonts()
end

---Updates font objects to match current screen scale
function TextUtil.updateFonts()
    local scale = (fore and fore.data and fore.data.scale) or 1
    
    scale = math.max(0.1, scale)

    if scale < 2 then scale = scale * 2 end

    TextUtil.fonts = {
        small = love.graphics.newFont("fore/assets/fonts/JetBrainsMono.ttf", 8, "normal", math.floor(TextUtil.base_font_sizes.small * scale)),
        medium = love.graphics.newFont("fore/assets/fonts/JetBrainsMono.ttf", 8, "normal", math.floor(TextUtil.base_font_sizes.medium * scale)),
        large = love.graphics.newFont("fore/assets/fonts/JetBrainsMono.ttf", 8, "normal", math.floor(TextUtil.base_font_sizes.large * scale))
    }
    
    for _, font in pairs(TextUtil.fonts) do
        font:setFilter("linear", "linear")
    end
end

---Automatically selects the correct font based on the scale
---@param s number The scale factor
---@return string The font name
function TextUtil.setFontScale(s)
    local font = "small"
    if s < 1.4 then font = "small"
    elseif s < 2.4 then font = "medium"
    else font = "large" end 
    love.graphics.setFont(TextUtil.fonts[font])
    return font
end

---Draws a text to the screen with smart scaling
---@param text string The text to render
---@param x number The x-coordinate
---@param y number The y-coordinate
---@param s number|table|nil The scale factor
---@param c number|table|nil The color
---@param wrap number|nil The wrap width
---@param align string|nil The alignment
---@return number Height of the text
function TextUtil.text(text, x, y, s, c, wrap, align)
    s = s or {1, 1}
    if type(s) == "number" then s = {s, s} end
    local sx = s[1] or 1
    local sy = s[2] or s[1]
    align = align or "left"

    local font = TextUtil.setFontScale(math.max(sx, sy))

    setColor(c)
    local height = 0
    if wrap then
        local width, lines = TextUtil.fonts[font]:getWrap(text, wrap/sx)
        love.graphics.printf(text, x, y, wrap/sx, align, 0, sx, sy)
        height = #lines * TextUtil.fonts[font]:getHeight() * sy
    else
        love.graphics.print(text, x, y, 0, sx, sy)
        height = TextUtil.fonts[font]:getHeight() * sy
    end
    return height
end

local function parseStyledText(str, defaultColor)
    local segments, stack, i = {}, { defaultColor }, 1
    str = str:gsub("%[br%]", "\n")
    while i <= #str do
        local s, e, cap = str:find("%[c=([%w_,]+)%]", i)
        local cs, ce = str:find("%[/c%]", i)
        local nextS = s or (#str + 1)
        local nextE = cs or (#str + 1)
        if nextS < nextE and nextS == i then
            local p = {}
            for v in cap:gmatch("[^,]+") do table.insert(p, tonumber(v) or v) end
            table.insert(stack, p)
            i = e + 1
        elseif nextE <= nextS and nextE == i then
            if #stack > 1 then table.remove(stack) end
            i = ce + 1
        else
            local stop = math.min(nextS, nextE)
            table.insert(segments, { text = str:sub(i, stop - 1), color = stack[#stack] })
            i = stop
        end
    end
    return segments
end

local function layoutStyledText(segments, maxWidth, scale)
    local lines, currentLine, currentWidth = {}, {}, 0
    local function flush()
        table.insert(lines, currentLine)
        currentLine, currentWidth = {}, 0
    end
    for _, seg in ipairs(segments) do
        local lastPos = 1
        while lastPos <= #seg.text do
            local nlS, nlE = seg.text:find("\n", lastPos)
            local part = seg.text:sub(lastPos, (nlS or 0) - 1)
            if #part > 0 then
                for word, space in part:gmatch("([^%s]+)(%s*)") do
                    local fW = word .. space
                    local w = TextUtil.getTextWidth(fW, scale)
                    if maxWidth and currentWidth + w > maxWidth and currentWidth > 0 then flush() end
                    table.insert(currentLine, { text = fW, color = seg.color })
                    currentWidth = currentWidth + w
                end
            end
            if nlS then flush() lastPos = nlE + 1 else break end
        end
    end
    table.insert(lines, currentLine)
    return lines
end

---Draws a text to the screen with smart scaling and tag system
---@param text string The text to render
---@param x number The x-coordinate
---@param y number The y-coordinate
---@param s number|table|nil The scale factor
---@param c number|table|nil The color
---@param wrap number|nil The wrap width
---@param align string|nil The alignment
---@return number Height of the text
function TextUtil.textAdvanced(text, x, y, s, c, wrap, align)
    s = type(s) == "table" and s[1] or s or 1
    local _, _, _, baseAlpha = coloring(c)

    TextUtil.setFontScale(s)

    local lineHeight = love.graphics.getFont():getHeight() * s
    local lines = layoutStyledText(parseStyledText(text, c), wrap, s)

    for i, line in ipairs(lines) do
        local cx = x
        if align and align ~= "left" and wrap then
            local lw = 0
            for _, seg in ipairs(line) do lw = lw + TextUtil.getTextWidth(seg.text, s) end
            cx = align == "center" and x + (wrap - lw)/2 or x + wrap - lw
        end
        for _, seg in ipairs(line) do
            local r, g, b, a = coloring(seg.color, baseAlpha)
            love.graphics.setColor(r, g, b, a)
            love.graphics.print(seg.text, cx, y + (i - 1) * lineHeight, 0, s, s)
            cx = cx + TextUtil.getTextWidth(seg.text, s)
        end
    end
    
    return #lines * lineHeight
end

---Draws a text to the screen and automatically chooses either text() or textAdvanced()
function TextUtil.textEx(text, x, y, s, c, wrap, align)
    if type(text) == "string" and (text:find("[c=", 1, true) or text:find("[br", 1, true)) then
        return TextUtil.textAdvanced(text, x, y, s, c, wrap, align)
    else
        return TextUtil.text(text, x, y, s, c, wrap, align)
    end
end

function TextUtil.getTextWidth(text, scale)
    scale = scale or 1
    local font = love.graphics.getFont()
    return font:getWidth(text) * scale
end

function TextUtil.getTextHeight(scale)
    scale = scale or 1
    local font = love.graphics.getFont()
    return font:getHeight() * scale
end

return TextUtil
