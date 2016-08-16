posterize = require("experiments/posterize")
wobble = require("experiments/wobble")

module.exports = (features, dimensions) ->
  canvas = document.createElement("canvas")
  ctx = canvas.getContext("2d")

  baseH = features.border.amount * features.border.height * features.brick.h
  baseH = baseH or 40

  railH = features.brick.h * features.sides.balconyHeight

  canvas.width  = dimensions.w
  canvas.height = dimensions.h + baseH

  ctx.lineWidth   = wobble(3, 1)
  ctx.fillStyle   = "#f4dabe"
  ctx.strokeStyle = "#00184d"

  ctx.beginPath()
  ctx.rect(0, 0, canvas.width, dimensions.height)
  ctx.fill()

  lw = ctx.lineWidth

  ctx.beginPath()
  ctx.rect(lw / 2, dimensions.h, canvas.width - lw, baseH - lw)
  ctx.moveTo(0, canvas.height - lw * 2)
  ctx.lineTo(canvas.width, canvas.height - lw * 2)
  ctx.stroke()

  ctx.beginPath()

  y = canvas.height - baseH - railH + features.brick.h
  h = railH - features.brick.h * 2

  switch features.sides.balconyStyle
    when "strokes"
      ctx.rect(lw / 2, canvas.height - baseH - railH, canvas.width - lw, railH)

      for i in [1...(canvas.width - lw) / features.brick.h]
        ctx.moveTo(i * features.brick.h + lw / 2, y)
        ctx.lineTo(i * features.brick.h + lw / 2, y + h)

      ctx.stroke()

    when "glass"
      hw = (canvas.width - features.brick.h - lw) / 2
      for i in [0, 1]
        ctx.rect(
          lw / 2 + i * (features.brick.h + hw), y,
          hw, h
        )

      ctx.stroke()

      ctx.beginPath()

      for i in [0..2]
        x = -lw / 2 + (i) * features.brick.h + i * hw - features.brick.h * 1.5
        ctx.rect(x, y + 8, features.brick.h * 3, 6)
        ctx.rect(x, y + h - 14, features.brick.h * 3, 6)

      ctx.fillStyle   = "#00184d"
      ctx.fill()

    when "bars"
      ctx.moveTo(0, y + 8)
      ctx.lineTo(canvas.width, y + 8)
      ctx.moveTo(0, y + h / 2)
      ctx.lineTo(canvas.width, y + h / 2)
      ctx.moveTo(0, y + h - 8)
      ctx.lineTo(canvas.width, y + h - 8)
      ctx.stroke()

      ctx.beginPath()
      w = (12 - lw)
      bars = Math.floor((canvas.width) / w)
      for i in [0...bars]
        w = (canvas.width) / (bars + 0.5)
        ctx.rect(
          i * w * 2 + lw / 2, y,
          w, h
        )

      ctx.fillStyle   = "#f4dabe"
      ctx.stroke()
      ctx.fill()

  if features.sides.balconyBar
    ctx.rect(lw / 2, canvas.height - baseH - railH - 8, canvas.width - lw, 8)

  ctx.stroke()

  posterize(canvas, 4)

  if features.sides.balconyInset and baseH > 20
    ctx.rect(
      lw / 2 + 8, canvas.height - baseH + 8,
      canvas.width - lw - 16, baseH - lw - 16
    )

    ctx.stroke()

    ctx.beginPath()
    ctx.moveTo(lw / 2 + 10, canvas.height - 16)
    ctx.lineTo(lw / 2 + 10, canvas.height - baseH + 10)
    ctx.lineTo(canvas.width - lw - 8, canvas.height - baseH + 10)
    ctx.globalAlpha = 0.3
    ctx.lineWidth = 10
    ctx.stroke()
    ctx.globalAlpha = 1

  mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
  mask
