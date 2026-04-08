return {
  fields = {
    { name = "x", type = "number", step = 1 },
    { name = "y", type = "number", step = 1 },
    { name = "w", type = "number", min = 1, default = 40 },
    { name = "h", type = "number", min = 1, default = 40 },
  },

  editor = {
    gizmo = "rectangle"
  },

  render = function(self)
    fore.graphics.rect(self.x, self.y, self.w, self.h, {0, 255, 100}, false)
  end
}