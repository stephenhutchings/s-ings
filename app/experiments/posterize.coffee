easie     = require("lib/easie")
color     = require("experiments/color")

palettes =
  default: [
    [244, 218, 190]
    [255, 255, 255]
    [29, 37, 53]
  ]

  grayscale: [
    [40, 40, 40]
    [210, 210, 210]
    [255, 255, 255]
  ]

cache   = []
colors  = palettes.default
offsets = [0.299, 0.587, 0.114]

# Ease time
ramp = (t) ->
  if (t *= 2) < 1
    return .5 * Math.pow(t, 3)
  else
    return .5 * ((t -= 2) * Math.pow(t, 2) + 2)

# Compute the distance between two colours
distance = (c1, c2) ->
  (
    Math.abs(c1[0] - c2[0]) * offsets[0] / 255 +
    Math.abs(c1[1] - c2[1]) * offsets[1] / 255 +
    Math.abs(c1[2] - c2[2]) * offsets[2] / 255
  )

process = (r, g, b, a) ->
  c = cache[r]?[g]?[b]

  unless c
    order = colors.sort((c0, c1) ->
      d0 = distance(c0, [r, g, b])
      d1 = distance(c1, [r, g, b])
      d0 - d1
    )

    c0 = order[0]
    c1 = order[1]

    d0 = distance(c0, [r, g, b])
    d1 = distance(c1, [r, g, b])

    dist = d0 + d1
    time = ramp d0 / dist

    cr = Math.floor c0[0] + (c1[0] - c0[0]) * time
    cg = Math.floor c0[1] + (c1[1] - c0[1]) * time
    cb = Math.floor c0[2] + (c1[2] - c0[2]) * time

    c = [cr, cg, cb]

    cache[r]      ?= []
    cache[r][g]   ?= []
    cache[r][g][b] = c

  return [c..., a]

module.exports = f = (cvs, r, c) ->
  if c? and c isnt colors
    colors = palettes[c] or c
    cache = []

  fx = new CanvasEffects(cvs, {useWorker: false})
  fx.noise(3)

  StackBlur.canvasRGB(cvs, 0, 0, cvs.width, cvs.height, r*1.5)
  fx.process(process)

  StackBlur.canvasRGB(cvs, 0, 0, cvs.width, cvs.height, r/2)
  fx.process(process)

  StackBlur.canvasRGB(cvs, 0, 0, cvs.width, cvs.height, 1)
  fx.process(process)
