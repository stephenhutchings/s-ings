colors = [
  [244, 218, 190]
  [255, 255, 255]
  [0, 24, 77]
]

offsets = [0.299, 0.587, 0.114]

distance = (c1, c2) ->
  (
    Math.abs(c1[0] - c2[0]) * offsets[0] +
    Math.abs(c1[1] - c2[1]) * offsets[1] +
    Math.abs(c1[2] - c2[2]) * offsets[2]
  ) / (255 * 3)

cache = []

process = (r, g, b, a) ->
  unless m = cache[r]?[g]?[b]

    d = 1

    if _.include [r, g, b], colors
      m = [r, g, b, a]

    else
      for c in colors
        if d >= dx = distance(c, [r, g, b])
          d = dx
          m = [c...]

      d = (d * d * d)

      for k, i in [r, g, b]
        diff = (k - m[i]) * 1
        m[i] += diff * d

    cache[r] = []
    cache[r][g] = []
    cache[r][g][b] = m

  [m..., a]

module.exports = (cvs, r, c) ->
  fx = new CanvasEffects(cvs, {useWorker: false})
  fx.noise(4)
  StackBlur.canvasRGB(cvs, 0, 0, cvs.width, cvs.height, r)

  if c?
    colors = c
    cache = []

  fx.process process
