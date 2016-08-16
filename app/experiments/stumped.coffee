badge     = require("experiments/badge")
layer     = require("experiments/layer")
shape     = require("experiments/shape")
smooth    = require("experiments/smooth")
wobble    = require("experiments/wobble")
resample  = require("experiments/resample")
sequence  = require("experiments/sequence")
posterize = require("experiments/posterize")
bigCanvas = require("experiments/big-canvas")
unmask    = require("experiments/threshold-to-mask")

module.exports =
  draw: ->
    { canvas, ctx } = bigCanvas(40)

    scale = 1.25

    canvas.width  *= scale
    canvas.height *= scale

    radius = Math.min(canvas.width, canvas.height) * wobble(0.7, 0.2) / 2

    ctx.fillStyle   = "#F4EAE1"
    ctx.beginPath()
    ctx.rect(0, 0, canvas.width, canvas.height)
    ctx.fill()

    sequence [
      => layer(ctx, @rings(canvas, radius))
      => layer(ctx, @cracks(canvas, radius))
      => layer(ctx, @grain(canvas, radius * scale))
      =>
        margin = 40
        { width, height, data } = badge("Stumped", 40 * scale)
        ctx.putImageData(data, canvas.width - width - margin, canvas.height - height - margin)
      => resample(ctx, canvas, scale)
    ]

  grain: ({ width, height}, radius) ->
    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    canvas.width = width
    canvas.height = height

    smaller = Math.min width, height

    ctx.beginPath()
    for j in [0.._.random(2, 8)]
      points = []
      for i in [0..3]
        a = wobble Math.PI * 2
        r = wobble radius
        x = width  / 2 + r * Math.cos(a)
        y = height / 2 + r * Math.sin(a)
        points.push x
        points.push y

        ctx.moveTo(x, y) if j is 0

      ctx.bezierCurveTo(points...)

    ctx.fillStyle = "#666"
    ctx.strokeStyle = "#fff"
    ctx.lineWidth = smaller / 200
    ctx.fill()
    ctx.stroke()

    StackBlur.canvasRGB(canvas, 0, 0, canvas.width, canvas.height, 20)

    fx = new CanvasEffects(canvas, {useWorker: false})
    fx.noise(60)
    fx.invert()
    smooth(canvas, _.random(6, 12), 124)

    mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
    unmask mask, 0, 24, 77
    mask

  cracks: ({ width, height }, radius) ->
    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    smaller = Math.min(width, height)

    canvas.width  = width
    canvas.height = height

    ctx.fillStyle = "#fff"

    pointWobble = smaller / 80

    cx = width  / 2
    cy = height / 2

    for i in [0.._.random(100)]
      a  = wobble Math.PI * 2
      r1 = radius * Math.random()
      r2 = radius * Math.random()
      r3 = Math.abs (r1 + r2) / 2
      x1 = cx + r1 * Math.cos(a) + wobble(pointWobble)
      y1 = cy + r1 * Math.sin(a) + wobble(pointWobble)
      x2 = cx + r2 * Math.cos(a) + wobble(pointWobble)
      y2 = cy + r2 * Math.sin(a) + wobble(pointWobble)
      x3 = cx + r3 * Math.cos(a) + wobble(pointWobble)
      y3 = cy + r3 * Math.sin(a) + wobble(pointWobble)
      x4 = cx + r3 * Math.cos(a) + wobble(pointWobble)
      y4 = cy + r3 * Math.sin(a) + wobble(pointWobble)

      ctx.moveTo x1, y1
      ctx.lineTo x3, y3
      ctx.lineTo x2, y2
      ctx.lineTo x4, y4
      ctx.lineTo x1, y1

    ctx.fill()

    smooth(canvas, 40)

    mask = ctx.getImageData(0, 0, width, height)
    unmask mask, 0, 24, 77
    mask

  rings: ({ width, height}, radius, scale) ->
    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    canvas.width = width
    canvas.height = height

    ctx.fillStyle   = "#f4dabe"
    ctx.strokeStyle = "#00184d"

    ctx.beginPath()
    ctx.rect(0, 0, canvas.width, canvas.height)
    ctx.fill()

    rings = _.random(80, 160)
    paths = _.random(12, 120)

    cx = canvas.width  / 2
    cy = canvas.height / 2

    ctx.beginPath()

    ox = oy = sx = sy = rw = a0 = 0
    radii = (wobble(12) for i in [0...paths])
    angls = (wobble(.01) for i in [0...paths])
    init  = wobble(Math.PI * 2 / 100)
    isOuter = false

    smaller = Math.min width, height

    variations =
      radialBase:  smaller / 400
      radialShift: smaller / 4
      limitBase:   smaller / 480
      limitShift:  smaller / 96
      pointStart:  smaller / 1600
      pointShift:  smaller / 4800
      radialJump:  [smaller / 120,  smaller / 40]
      innerWidth:  smaller  / 4000
      outerWidth:  [smaller / 480, smaller / 120]

    for ring in [0...rings]

      if not isOuter
        if ring + 1 >= _.random(rings - 1, rings)
          radius += _.random(variations.radialJump...)
          isOuter = true
          ctx.lineWidth = _.random(variations.outerWidth...)
          ctx.strokeStyle = "#00184d"
        else
          mult = Math.sin (ring / rings) * Math.PI
          ctx.lineWidth = wobble(variations.innerWidth * 1.5 + mult * variations.innerWidth * 2, variations.innerWidth * (1 + mult))
          ctx.strokeStyle = if Math.random() < 0.082 then "#fff" else "#00184d"

      rw     = wobble rw, 4
      r      = wobble rw + ring / rings * radius, 8
      init   = wobble(init, Math.PI * 2 / 100)
      init   = ring / rings * Math.PI * 2

      ctx.beginPath()
      a0 = wobble a0, (1 - (i + 1) / paths)

      for i in [0...paths]

        angls[i] = wobble(angls[i], 0.001)

        progress = (ring / rings)
        diff     = 0.004 / Math.abs(0.004 - angls[i])
        limit    = (variations.limitBase + progress * variations.limitShift) * diff
        amount   = (variations.radialBase / paths) + (variations.radialShift / paths) * progress
        radii[i] = wobble radii[i], amount, limit

        r1 = r + radii[i]
        r2 = r + radii[(i + 1) % radii.length]

        a1 = angls[i] + (Math.PI * 2) * ((i - 1) / (paths)) + a0
        a2 = angls[(i + 1) % angls.length] + (Math.PI * 2) * (i / (paths)) + a0

        x1 = cx + r1 * Math.cos(a1)
        y1 = cy + r1 * Math.sin(a1)
        x4 = cx + r2 * Math.cos(a2)
        y4 = cy + r2 * Math.sin(a2)
        x2 = x1 + r1 * Math.cos(a1 + Math.PI / 2) / (paths / wobble(variations.pointStart, variations.pointShift))
        y2 = y1 + r1 * Math.sin(a1 + Math.PI / 2) / (paths / wobble(variations.pointStart, variations.pointShift))
        x3 = x4 - r2 * Math.cos(a2 + Math.PI / 2) / (paths / wobble(variations.pointStart, variations.pointShift))
        y3 = y4 - r2 * Math.sin(a2 + Math.PI / 2) / (paths / wobble(variations.pointStart, variations.pointShift))

        if i is 0
          sx = x1
          sy = y1
          ctx.moveTo(x1, y1)

        if i is paths - 1
          x4 = sx
          y4 = sy

        ctx.bezierCurveTo(x2, y2, x3, y3, x4, y4)

        cx += wobble(variations.pointShift)
        cy += wobble(variations.pointShift)

      ctx.closePath()
      ctx.stroke()

    posterize(canvas, 2 * scale)
    mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
    mask
