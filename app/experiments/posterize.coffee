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

do buildCache = ->
  for r in [0..255]
    cache[r] = []
    for g in [0..255]
      cache[r][g] = []

process = (r, g, b, a) ->
  m = cache[r][g][b]

  if not m
    d = 1
    j = [r, g, b]

    for c in colors
      if d >= dx = distance(c, j)
        d = dx
        m = [c...]

    d = Math.pow(d, 3)

    for k, i in j
      diff = (k - m[i])
      m[i] = Math.round(m[i] + diff * d)

    cache[r]      ?= []
    cache[r][g]   ?= []
    cache[r][g][b] = m

  [m..., a]

module.exports = (cvs, r, c) ->
  fx = new CanvasEffects(cvs, {useWorker: false})
  fx.noise(5)
  StackBlur.canvasRGB(cvs, 0, 0, cvs.width, cvs.height, r)

  if c?
    colors = c
    buildCache()

  fx.process(process)
