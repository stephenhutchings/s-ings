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
  draw: (options, done) ->
    { canvas, ctx } = bigCanvas(options)

    scale = 1.2

    canvas.width  *= scale
    canvas.height *= scale

    smaller = Math.min(canvas.width, canvas.height)
    radius  = smaller * wobble(0.7, 0.2) / 2

    ctx.fillStyle   = "#f4dabe"
    ctx.beginPath()
    ctx.rect(0, 0, canvas.width, canvas.height)
    ctx.fill()

    features =
      radius: radius
      radialBase:  smaller / 400
      radialShift: smaller / 4
      limitBase:   smaller / 480
      limitShift:  smaller / 96
      pointStart:  smaller / 1600
      pointShift:  smaller / 4800
      radialJump:  [smaller / 120,  smaller / 40]
      innerWidth:  smaller  / 3000
      outerWidth:  [smaller / 240, smaller / 60]

    features.center =
      x: canvas.width  / 2
      y: canvas.height / 2

    sequence [
      => layer(ctx, @rings(canvas, features))
      => layer(ctx, @cracks(canvas, features))
      => layer(ctx, @grain(canvas, features))
      =>
        margin = 48 * scale
        { width, height, data } = badge(24 * scale)
        ctx.putImageData data,
          (canvas.width - width) / 2
          canvas.height - height - margin

      => posterize(canvas, radius / 400)
      => resample(ctx, canvas, scale)
      -> done canvas
    ]

  grain: ({ width, height}, features) ->
    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    radius = features.radius * 2
    cx = features.center.x
    cy = features.center.y

    canvas.width = width
    canvas.height = height

    ctx.beginPath()
    for j in [0.._.random(2, 8)]
      points = []
      for i in [0..3]
        a = wobble Math.PI * 2
        r = wobble radius
        x = cx + r * Math.cos(a)
        y = cy + r * Math.sin(a)
        points.push x
        points.push y

        ctx.moveTo(x, y) if j is 0

      ctx.bezierCurveTo(points...)

    ctx.fillStyle = "#666"
    ctx.strokeStyle = "#fff"
    ctx.lineWidth = Math.min(width, height) / 200
    ctx.fill()
    ctx.stroke()

    StackBlur.canvasRGB(canvas, 0, 0, canvas.width, canvas.height, 20)

    fx = new CanvasEffects(canvas, {useWorker: false})
    fx.noise(60)
    fx.invert()
    smooth(canvas, _.random(3, 8), 124)

    mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
    unmask mask, 0, 24, 77
    mask

  cracks: ({ width, height }, features) ->
    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    canvas.width  = width
    canvas.height = height

    ctx.fillStyle = "#fff"
    ctx.strokeStyle = "#fff"

    pointWobble = Math.min(width, height) / 80

    radius = features.radius
    cx = features.center.x
    cy = features.center.y

    for i in [0.._.random(10, 100)]
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
      x4 = wobble(x3, pointWobble)
      y4 = wobble(y3, pointWobble)

      ctx.moveTo x1, y1
      ctx.lineTo x3, y3
      ctx.lineTo x2, y2
      ctx.lineTo x4, y4
      ctx.lineTo x1, y1

    ctx.fill()
    ctx.stroke()

    smooth(canvas, _.random(15, 30))

    mask = ctx.getImageData(0, 0, width, height)
    unmask mask, 0, 24, 77
    mask

  rings: ({ width, height}, features) ->
    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")
    radius = features.radius

    canvas.width = width
    canvas.height = height

    ctx.fillStyle   = "#f4dabe"
    ctx.strokeStyle = "#00184d"

    ctx.beginPath()
    ctx.rect(0, 0, canvas.width, canvas.height)
    ctx.fill()

    rings = _.random(80, 160)
    paths = _.random(12, 120)

    cx = features.center.x
    cy = features.center.y

    ctx.beginPath()

    ox = oy = sx = sy = rw = a0 = 0
    radii = (wobble(12) for i in [0...paths])
    angls = (wobble(.01) for i in [0...paths])
    init  = wobble(Math.PI * 2 / 100)
    isOuter = false

    instructions =
      for ring in [0...rings]
        factor = ring / rings
        style  = {}

        if not isOuter
          if ring + 1 >= _.random(rings - 1, rings)
            radius += _.random(features.radialJump...) * factor
            isOuter = true
            style.lineWidth = _.random(features.outerWidth...)
            style.strokeStyle = "#00184d"
          else
            mult = Math.sin (ring / rings) * Math.PI
            style.lineWidth = wobble(features.innerWidth * 1.5 + mult * features.innerWidth * 2, features.innerWidth * (1 + mult))
            style.strokeStyle = if Math.random() < 0.082 then "#ffffff" else "#00184d"
            style.lineWidth *= _.random(2, 12) if style.strokeStyle is "#ffffff"


        rw     = wobble rw, 4
        r      = wobble rw + ring / rings * radius, 8
        init   = wobble(init, Math.PI * 2 / 100)
        init   = ring / rings * Math.PI * 2

        a0 = wobble a0, (1 - (i + 1) / paths)

        style: style
        paths: for i in [0...paths]
          angls[i] = wobble(angls[i], 0.001)

          diff     = 0.004 / Math.abs(0.004 - angls[i])
          limit    = (features.limitBase + features.limitShift) * diff * factor
          amount   = (features.radialBase / paths) + (features.radialShift / paths) * factor
          radii[i] = wobble radii[i], amount, limit

          r1 = r + radii[i]
          r2 = r + radii[(i + 1) % radii.length]

          a1 = angls[i] + (Math.PI * 2) * ((i - 1) / (paths)) + a0
          a2 = angls[(i + 1) % angls.length] + (Math.PI * 2) * (i / (paths)) + a0

          x1 = cx + r1 * Math.cos(a1)
          y1 = cy + r1 * Math.sin(a1)
          x4 = cx + r2 * Math.cos(a2)
          y4 = cy + r2 * Math.sin(a2)
          x2 = x1 + r1 * Math.cos(a1 + Math.PI / 2) / (paths / wobble(features.pointStart, features.pointShift))
          y2 = y1 + r1 * Math.sin(a1 + Math.PI / 2) / (paths / wobble(features.pointStart, features.pointShift))
          x3 = x4 - r2 * Math.cos(a2 + Math.PI / 2) / (paths / wobble(features.pointStart, features.pointShift))
          y3 = y4 - r2 * Math.sin(a2 + Math.PI / 2) / (paths / wobble(features.pointStart, features.pointShift))

          cx += wobble(features.pointShift)
          cy += wobble(features.pointShift)

          if i is 0
            sx = x1
            sy = y1
            [x1, y1]

          else
            if i is paths - 1
              x4 = sx
              y4 = sy

            [x2, y2, x3, y3, x4, y4]

    for { paths, style }, i in instructions
      ctx.beginPath()
      ctx[key] = val for key, val of style
      for path, j in paths
        ctx[if j is 0 then "moveTo" else "bezierCurveTo"](path...)

      ctx.closePath()
      ctx.stroke()

    mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
    mask
