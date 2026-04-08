return {
  fields = {
    { name = "x", type = "number", step = 1 },
    { name = "y", type = "number", step = 1 },
    { name = "w", type = "number", min = 1 },
    { name = "h", type = "number", min = 1 },
    { name = "color", type = "color" },
  },

  editor = {
    gizmo = "rectangle"
  },

  render = function(self)
    fore.graphics.rect(self.x, self.y, self.w, self.h, self.color)
  end
}