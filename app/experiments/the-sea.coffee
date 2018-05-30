# coffeelint: disable:max_line_length

badge     = require("experiments/badge")
bigCanvas = require("experiments/big-canvas")
frame     = require("experiments/frame")
layer     = require("experiments/layer")
posterize = require("experiments/posterize")
resample  = require("experiments/resample")
sequence  = require("experiments/sequence")
shape     = require("experiments/shape")
unmask    = require("experiments/threshold-to-mask")
wobble    = require("experiments/wobble")

module.exports =
  draw: (options, done) ->
    { canvas, ctx } = bigCanvas(options)

    scale = options.scale or 1.1

    canvas.width  *= scale
    canvas.height *= scale

    smaller = Math.min(canvas.width, canvas.height)
    outer   = (smaller) / 12

    sequence [
      => layer(ctx, @arcs(canvas, outer))
      -> layer(ctx, frame(canvas, Math.max(smaller / 40 - 24, 20)))
      ->
        height = Math.max(smaller / 40 - 24, 20)
        margin = height * 4
        { width, height, data } = badge(height)
        ctx.putImageData(data, (canvas.width - width) / 2, canvas.height - height - margin)

      -> posterize(canvas, Math.pow(scale, 0.35) * outer / 44, "grayscale")
      -> resample(ctx, canvas, scale)
      -> done canvas
    ]

  arcs: ({ width, height}, outer) ->
    inner = 1
    rings = 12

    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    canvas.width = width
    canvas.height = height

    ctx.fillStyle   = "#ddd"
    ctx.strokeStyle = "#000"

    y = row = 0

    rWidth = wobble(outer, outer / 2)
    w = outer * 0.1
    lw = w / 6

    while y < canvas.height + rWidth
      y = row * (rWidth * 0.33)
      x = wobble(-rWidth * (row % 2), rWidth * 0.25)
      row++

      while x < canvas.width + rWidth
        width  = wobble(rWidth, w / 2)
        height = wobble(rWidth, w)

        for i in [0..rings]
          for repeat in [0..2]
            ctx.lineWidth = wobble(lw, lw * 0.5)
            radius = height - (height - inner) * (i / rings)
            cw = width - (width - inner) * (i / rings)
            cr = wobble(radius, w / 6)
            cx = wobble(x, w / 3)
            cy = wobble(y, w / 3)

            top = wobble cy - cr * 1.3, w / 6

            ctx.beginPath()
            ctx.moveTo cx - cw, cy
            ctx.bezierCurveTo(
              wobble(cx - cw, w), wobble(cy - cr * 0.4, w)
              wobble(cx - cw * 0.66, w), top
              cx, top
            )
            ctx.bezierCurveTo(
              wobble(cx + cw * 0.66, w), top
              wobble(cx + cw, w), wobble(cy - cr * 0.4, w)
              wobble(cx + cw, w), cy
            )

            ctx.stroke()
            ctx.fill() if repeat is 0

            if Math.random() > 0.982
              ctx.fillStyle = _.sample ["#000", "#fff"]
              ctx.fill()
            else
              ctx.fillStyle = "#ddd"

        x += width * 2

    mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
    mask
