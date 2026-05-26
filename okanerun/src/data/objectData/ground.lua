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
      local c = (mobileContrastStatus or fore.data.phone) and {25, 30, 45} or {15, 20, 28}
      local ca = {c[1], c[2], c[3], 30}

      local drawOutline = function()
        fore.graphics.rect(self.x, self.y, self.w, self.h, {0,0,0,63}, false)
        fore.graphics.rect(self.x-1, self.y-1, self.w+2, self.h+2, {0,0,0,63}, false)
      end
      
      local drawMain = function()
          fore.graphics.rect(self.x, self.y, self.w, self.h, c)
          if not (mobileContrastStatus or fore.data.phone) then
            for gx = self.x, self.x + self.w-1, 40 do
                for gy = self.y, self.y + self.h-1, 40 do
                    fore.graphics.rect(gx, gy, 1, 1, {150, 200, 255, 20})
                end
            end
          else
            for gx = self.x, self.x + self.w-2, 40 do
                for gy = self.y, self.y + self.h-2, 40 do
                    fore.graphics.rect(gx, gy, 2, 2, {150, 200, 255, 15})
                end
            end
          end
      end

      local drawDec = function()
          fore.graphics.rect(self.x, self.y+20, self.w, self.h+20, ca)
          fore.graphics.rect(self.x, self.y+15, self.w, self.h+15, ca)
          fore.graphics.rect(self.x, self.y+10, self.w, self.h+10, ca)
          fore.graphics.rect(self.x, self.y+5,  self.w, self.h+5,  ca)
      end

      if isEditor then
          drawMain()
          drawDec()
      else
          fore.queuer.submit(L.FLOOR, self.y, drawMain)
          fore.queuer.submit(L.FLOOR_DEC, self.y, drawDec)
          if (mobileContrastStatus or fore.data.phone) then
            fore.queuer.submit(L.FLOOR_DEC, self.y + 10000, drawOutline)
          end
      end
  end
}