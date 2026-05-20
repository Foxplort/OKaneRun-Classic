return {
  fields = {
    { name = "x", type = "number", step = 1 },
    { name = "y", type = "number", step = 1 },
    { name = "w", type = "number", min = 1 },
    { name = "h", type = "number", min = 1 },
  },

  editor = {
    gizmo = "rectangle",
    color = {1.0, 0.2, 0.2, 0.6},
    layer = "Subactor"
  },

  hitbox = function(self)
      return {x = self.x, y = self.y, w = self.w, h = self.h}
  end,

  render = function(self, isEditor)
      local drawMain = function()
          fore.graphics.rect(self.x, self.y, self.w, self.h, {0, 190, 80}, false)
      end

      if isEditor then
          drawMain()
      else
          fore.queuer.submit(L.SHADOW, self.y, drawMain)
      end
  end
}