return {
  fields = {
    { name = "x", type = "number", step = 1 },
    { name = "y", type = "number", step = 1 },
  },

  editor = {
    gizmo = "point",
    color = {1.0, 0.8, 0.1, 1.0},
    layer = "Actor"
  },

  hitbox = function(self)
      return {x = self.x - 8, y = self.y - 6, w = 16, h = 12}
  end,

  render = function(self, isEditor)
      local drawLogic = function()
          fore.graphics.circ(self.x-6, self.y-15+1, 10, 15, {230, 140, 0}, true, 7) -- outline
          fore.graphics.circ(self.x-5, self.y-15, 10, 15, {255, 200, 0}, true, 7) -- body
          fore.graphics.circ(self.x-1, self.y-13, 2, 10, {230, 140, 0}, true, 4) -- middle
          fore.graphics.circ(self.x+1, self.y-13, 4, 5, {255, 255, 160}, true, 5) -- highlight
          fore.graphics.circ(self.x+2.5, self.y-12, 2, 3, {255, 255, 255}, true, 5) -- highlight
      end

      local shadowLogic = function()
          local z = 5
          local cw, ch = 10, 7
          local baseW = cw * 1.2
          local baseH = ch * 0.35
          local shadowZ = math.max(0, z)
          local shrink = math.max(0.45, 1 - shadowZ / 80)
          local w = baseW * shrink
          local h = baseH * shrink
          local alpha = math.max(60, 160 - z * 1.5)
          local cx = self.x + cw * 0.5 - 5
          local cy = self.y - 2
          fore.graphics.circ(cx - w * 0.5, cy - h * 0.5 + 2, w, h, {0, 0, 0, alpha})
      end

      if isEditor then
          drawLogic()
          shadowLogic()
      else
          fore.queuer.submit(L.ACTOR, self.y, drawLogic)
          fore.queuer.submit(L.SHADOW, self.y, shadowLogic)
      end
  end
}