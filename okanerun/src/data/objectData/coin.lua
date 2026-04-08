return {
  fields = {
    { name = "x", type = "number", step = 1 },
    { name = "y", type = "number", step = 1 },
  },

  editor = {
    gizmo = "point"
  },

  render = function(self)
    fore.graphics.midCirc("fill", self.x, self.y, 5)
  end
}