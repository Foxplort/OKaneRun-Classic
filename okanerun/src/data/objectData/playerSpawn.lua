return {
  fields = {
    { name = "x", type = "number", step = 1 },
    { name = "y", type = "number", step = 1 },
    { name = "z", type = "number", step = 1, default = 1 },
    { name = "offsetX", type = "number", step = 1, default = -16 },
    { name = "offsetY", type = "number", step = 1, default = -40 }
  },

  editor = {
    gizmo = "point"
  },

  render = function(self, isEditor)
     love.graphics.circle("fill", self.x, self.y, 5)
  end
}