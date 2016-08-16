badge     = require("experiments/badge")
resample  = require("experiments/resample")
posterize = require("experiments/posterize")
shape     = require("experiments/shape")
unmask    = require("experiments/threshold-to-mask")
bigCanvas = require("experiments/big-canvas")
sequence  = require("experiments/sequence")
wobble    = require("experiments/wobble")
layer     = require("experiments/layer")

dpi   = window.webkitDevicePixelRatio or window.devicePixelRatio or 1
scale = 1.5

module.exports =
  draw: ->
    { canvas, ctx } = bigCanvas(40)

    canvas.width  *= scale
    canvas.height *= scale

    sequence [
      => layer(ctx, @arcs(canvas))
      =>
        margin = 20 * dpi * scale
        { width, height, data } = badge("The  Sea", margin)
        ctx.putImageData(
          data
          canvas.width - width - margin
          canvas.height - height - margin
        )

      => posterize(canvas, 1.25 * dpi * scale)
      # => resample(ctx, canvas, scale)

    ]

  arcs: ({ width, height}, radius) ->
    inner = 1
    outer = 90 * dpi
    rings = 12

    canvas = document.createElement("canvas")
    ctx    = canvas.getContext("2d")

    canvas.width = width
    canvas.height = height

    ctx.fillStyle   = "#f4dabe"
    ctx.strokeStyle = "#00184d"

    y = row = 0

    outer = wobble(outer, 60 * dpi)

    while y < canvas.height + outer
      y = row * (outer * 0.33)
      x = -outer * (row % 2)
      row++

      yOffset = wobble(4 * dpi)
      xOffset = wobble(4 * dpi)

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
              ctx.fillStyle = _.sample ["#00184d", "#fff"]
              ctx.fill()
            else
              ctx.fillStyle = "#f4dabe"

        x += width * 2

    mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
    mask
