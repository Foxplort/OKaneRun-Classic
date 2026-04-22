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
    color = {0.5, 0.5, 0.5, 1.0}
  },

  hitbox = function(self)
      return {x = self.x, y = self.y, w = self.w, h = self.h}
  end,

  render = function(self, isEditor)
      local drawMain = function()
          fore.graphics.rect(self.x, self.y, self.w, self.h, {15, 20, 28})
          for gx = self.x, self.x + self.w-1, 40 do
              for gy = self.y, self.y + self.h-1, 40 do
                  fore.graphics.rect(gx, gy, 1, 1, {150, 200, 255, 20})
              end
          end
      end

      local drawDec = function()
          fore.graphics.rect(self.x, self.y+20, self.w, self.h+20, {15, 20, 28, 30})
          fore.graphics.rect(self.x, self.y+15, self.w, self.h+15, {15, 20, 28, 30})
          fore.graphics.rect(self.x, self.y+10, self.w, self.h+10, {15, 20, 28, 30})
          fore.graphics.rect(self.x, self.y+5,  self.w, self.h+5,  {15, 20, 28, 30})
      end

      if isEditor then
          drawMain()
          drawDec()
      else
          fore.queuer.submit(L.FLOOR, self.y, drawMain)
          fore.queuer.submit(L.FLOOR_DEC, self.y + self.w, drawDec)
      end
  end
}