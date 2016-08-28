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

dpi   = window.webkitDevicePixelRatio or window.devicePixelRatio or 1

module.exports =
  draw: (options, done) ->
    { canvas, ctx } = bigCanvas(options)

    scale = options.scale or 2.5

    canvas.width  *= scale
    canvas.height *= scale

    sequence [
      => layer(ctx, @arcs(canvas))
      -> layer(ctx, frame(canvas, scale * 20))
      ->
        margin = 24 * dpi * scale
        { width, height, data } = badge(margin / dpi)
        ctx.putImageData(
          data
          (canvas.width - width) / 2
          canvas.height - height - margin
        )

      -> posterize(canvas, Math.pow(scale, 0.35) * dpi * 1.5, "grayscale")
      -> resample(ctx, canvas, scale)
      -> done canvas
    ]

  arcs: ({ width, height}) ->
    inner = 1
    outer = 90 * dpi
    rings = 12

    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    canvas.width = width
    canvas.height = height

    ctx.fillStyle   = "#ddd"
    ctx.strokeStyle = "#000"

    y = row = 0

    outer = wobble(outer, 60 * dpi)

    while y < canvas.height + outer
      y = row * (outer * 0.33)
      x = wobble(-outer * (row % 2), 16 * dpi)
      row++

      while x < canvas.width + outer
        width  = wobble(outer,  6 * dpi)
        height = wobble(outer, 16 * dpi)

        for i in [0..rings]
          for repeat in [0..2]
            ctx.lineWidth = wobble(2, 1)
            radius = height - (height - inner) * (i / rings)
            cw = width - (width - inner) * (i / rings)
            cr = wobble(radius, 2)
            cx = wobble(x, 4)
            cy = wobble(y, 4)

            top = wobble cy - cr * 1.3, 3

            ctx.beginPath()
            ctx.moveTo cx - cw, cy
            ctx.bezierCurveTo(
              wobble(cx - cw, 8), wobble(cy - cr * 0.4, 8)
              wobble(cx - cw * 0.66, 8), top
              cx, top
            )
            ctx.bezierCurveTo(
              wobble(cx + cw * 0.66, 8), top
              wobble(cx + cw, 8), wobble(cy - cr * 0.4, 8)
              wobble(cx + cw, 8), cy
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
