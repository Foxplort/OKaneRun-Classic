-- Predefined colors
local col = {
  {0,0,0,63},
  {25, 30, 45},
  {15, 20, 28},
  {150, 200, 255, 15},
  {150, 200, 255, 20}
}

-- Decoration colors
local ca_desktop = {col[3][1], col[3][2], col[3][3], 30}
local ca_mobile  = {col[2][1], col[2][2], col[2][3], 30}

-- Draw functions
local function drawOutline(t)
  fore.draw2d.rect(t.x, t.y, t.w, t.h, col[1], false)
  fore.draw2d.rect(t.x-1, t.y-1, t.w+2, t.h+2, col[1], false)
end

local function drawMain(t)
  local c = (mobileContrastStatus or fore.data.phone) and col[2] or col[3]
  fore.draw2d.rect(t.x, t.y, t.w, t.h, c)
  if not (mobileContrastStatus or fore.data.phone) then
    for gx = t.x, t.x + t.w-1, 40 do
      for gy = t.y, t.y + t.h-1, 40 do
        fore.draw2d.rect(gx, gy, 1, 1, col[5])
      end
    end
  else
    for gx = t.x, t.x + t.w-2, 40 do
      for gy = t.y, t.y + t.h-2, 40 do
        fore.draw2d.rect(gx, gy, 2, 2, col[4])
      end
    end
  end
end

local function drawDec(t)
  local ca = (mobileContrastStatus or fore.data.phone) and ca_mobile or ca_desktop
  fore.draw2d.rect(t.x, t.y+20, t.w, t.h+20, ca)
  fore.draw2d.rect(t.x, t.y+15, t.w, t.h+15, ca)
  fore.draw2d.rect(t.x, t.y+10, t.w, t.h+10, ca)
  fore.draw2d.rect(t.x, t.y+5,  t.w, t.h+5,  ca)
end

return {
  fields = {
    { name = "x", type = "number", step = 1 },
    { name = "y", type = "number", step = 1 },
    { name = "w", type = "number", min = 1 },
    { name = "h", type = "number", min = 1 },
    { name = "color", type = "color" },
  },

  editor = {
    gizmo = "rectangle",
    color = {0.5, 0.5, 0.5, 1.0},
    layer = "Floor"
  },

  hitbox = function(self)
      return {x = self.x, y = self.y, w = self.w, h = self.h}
  end,

  render = function(self, isEditor)
      if isEditor then
          drawMain(self)
          drawDec(self)
      else
          fore.queuer.submit(L.FLOOR, self.y, function() drawMain(self) end)
          fore.queuer.submit(L.FLOOR_DEC, self.y, function() drawDec(self) end)
          if (mobileContrastStatus or fore.data.phone) then
            fore.queuer.submit(L.FLOOR_DEC, self.y + 10000, function() drawOutline(self) end)
          end
      end
  end
}
