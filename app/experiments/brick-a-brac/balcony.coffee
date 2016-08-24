posterize = require("experiments/posterize")
wobble = require("experiments/wobble")

module.exports = (features, dimensions, side, floor) ->
  canvas = document.createElement("canvas")
  ctx = canvas.getContext("2d")

  baseH = features.border.amount * features.border.height * features.brick.h
  baseH = baseH or 40
  suppH = _.random(20, 30)

  railH = features.brick.h * features.sides.balconyHeight

  canvas.width  = dimensions.w
  canvas.height = dimensions.h + baseH + suppH

  ctx.lineWidth   = wobble(3, 1)
  ctx.fillStyle   = "#f4dabe"
  ctx.strokeStyle = "#00184d"

  ctx.beginPath()
  ctx.rect(0, 0, canvas.width, canvas.height)
  ctx.fill()

  lw = ctx.lineWidth

  ctx.beginPath()
  ctx.rect(lw / 2, dimensions.h, canvas.width - lw, baseH - lw)
  ctx.moveTo(0, dimensions.h + baseH - lw)
  ctx.lineTo(canvas.width, dimensions.h + baseH - lw)
  ctx.stroke()

  ctx.beginPath()

  y = dimensions.h - railH + features.brick.h
  h = railH - features.brick.h * 2

  switch features.sides.balconyStyle = "strokes"
    when "strokes"
      ctx.rect(lw / 2, dimensions.h - railH, canvas.width - lw, railH)

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

      ctx.fillStyle = "#00184d"
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

      ctx.fillStyle = "#f4dabe"
      ctx.stroke()
      ctx.fill()

  if features.sides.balconyBar
    ctx.beginPath()
    ctx.rect(lw / 2, y + h - railH - 8, canvas.width - lw, 8)
    ctx.stroke()

  if baseH > 20
    if features.sides.balconyInset
      ctx.beginPath()
      ctx.rect(
        lw / 2 + 8, y + h + 16,
        canvas.width - lw - 16, baseH - lw - 16
      )
      ctx.stroke()

  else
    # Support
    ctx.lineWidth = _.random(6, 8)
    ctx.beginPath()
    ctx.moveTo(canvas.width / 2, y + h + baseH / 2 + 8)
    ctx.lineTo((if side is 0 then canvas.width else 0), canvas.height)
    ctx.stroke()

  posterize(canvas, wobble(3, 1))

  if features.sides.balconyInset and baseH > 20
    ctx.beginPath()
    ctx.moveTo(lw / 2 + 10, y + h + baseH - 16)
    ctx.lineTo(lw / 2 + 10, y + h + 16)
    ctx.lineTo(canvas.width - lw - 8, y + h + 16)
    ctx.globalAlpha = 0.3
    ctx.lineWidth = 10
    ctx.stroke()
    ctx.globalAlpha = 1


  mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
  mask
