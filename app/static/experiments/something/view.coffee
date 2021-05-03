badge     = require("experiments/badge")
layer     = require("experiments/layer")
frame     = require("experiments/frame")
maybe     = require("experiments/maybe")
smooth    = require("experiments/smooth")
wobble    = require("experiments/wobble")
resample  = require("experiments/resample")
sequence  = require("experiments/sequence")
posterize = require("experiments/posterize")
bigCanvas = require("experiments/big-canvas")

module.exports =
  draw: (options, done) ->
    { canvas, ctx } = bigCanvas(options)

    scale = options.scale or 1.25

    canvas.width  *= scale
    canvas.height *= scale

    smaller = Math.min(canvas.width, canvas.height)

    ctx.fillStyle = "#ddd"
    ctx.beginPath()
    ctx.rect(0, 0, canvas.width, canvas.height)
    ctx.fill()

    [fn1, fn2] = _.sample _.shuffle(["sin", "tan", "cos"]), 2

    dv = _.random smaller / 50

    loopiness = _.random(1, 100) / 1000

    features = { smaller, fn1: "sin", fn2: "cos", dv, loopiness }

    sequence [
      =>
        x = y = 0
        sequence (
          for i in [0...180]
            do (i) => =>
              { x, y, dv, data} = @rings(canvas, features)
              _.extend features, { x, y, i, dv }
              layer(ctx, data)
        )

      -> layer(ctx, frame(canvas, Math.max(smaller / 40 - 24, 20)))
      ->
        height = Math.max(smaller / 40 - 24, 20)
        margin = height * 4
        { width, height, data } = badge(height)
        ctx.putImageData(
          data,
          (canvas.width - width) / 2,
          canvas.height - height - margin
        )

      -> posterize(canvas, Math.pow(scale, 0.35) * smaller / 400, "grayscale")
      -> resample(ctx, canvas, scale)
      -> done canvas
    ]

  rings: ({ width, height}, features) ->
    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    canvas.width = width
    canvas.height = height

    cx = features.x or _.random width
    cy = features.y or _.random height
    dt = Math.PI / 90
    dr = features.smaller / 500
    dv = features.dv

    t = wobble Math.PI * 2

    tone = if maybe(0.7) then 0 else 255
    rgb  = (tone for i in [0...3])

    ctx.strokeStyle = ctx.fillStyle = "rgba(#{rgb.join(",")}, 0.5)"
    # ctx.shadowBlur = 10
    # ctx.shadowColor = ctx.strokeStyle
    ctx.lineWidth = 0.4
    ctx.beginPath()

    ctx.moveTo cx, cy

    [fn1, fn2] = _.sample _.shuffle(["sin", "tan", "cos"]), 2
    [fn1, fn2] = ["sin", "cos"]
    { fn1, fn2 } = features

    points =
      for i in [0...2000]
        dv = wobble dv, 0.1
        dv = Math.max Math.min(dv, 2), 0.05

        v = dv
        t += dt

        if maybe(features.loopiness)
          dt *= -1

        x = cx + Math[fn1](t) * v
        y = cy + Math[fn2](t) * v
        r = wobble dr, features.smaller / 400

        if 0 >= x or x >= width or 0 >= y or y >= height
          dt -= Math.PI
          x = cx + Math[fn1](t) * v
          y = cy + Math[fn2](t) * v

        ctx.lineTo x, y
        ctx.arc x, y, r, 0, Math.PI * 2

        cx = x
        cy = y

        [x, y]

    for [x2, y2] in points.reverse()
      ctx.lineTo x2, y2

    ctx.stroke()
    ctx.fill()

    # StackBlur.canvasRGBA canvas, 0, 0, canvas.width, canvas.height, 3

    data = ctx.getImageData(0, 0, canvas.width, canvas.height)
    { x, y, data, dv }

  getImage: (done) ->
    canvas = document.createElement("canvas")
    ctx = canvas.getContext("2d")

    r = 10

    canvas.width = canvas.height = r * 4

    ctx.arc(r * 2, r * 2, r, 0, Math.PI * 2)
    ctx.fill()
    StackBlur.canvasRGBA canvas, 0, 0, r * 4, r * 4, r

    img = new Image()
    img.onload = -> done(this)
    img.src = canvas.toDataURL()
