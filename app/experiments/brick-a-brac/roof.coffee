wobble    = require("experiments/wobble")
posterize = require("experiments/posterize")

module.exports = (features) ->
  bw = features.brick.w
  bh = features.brick.h
  tw = features.brick.h * 2

  canvas = document.createElement("canvas")
  ctx    = canvas.getContext("2d")

  w = features.floors.w * bw
  h = features.roof.h

  padding = bh * 2 * -Math.min(features.roof.inset, 0)
  canvas.width  = w + padding
  canvas.height = h + bh * (features.roof.base + 1)

  # ctx.fillStyle = "red"
  # ctx.rect(0, 0, canvas.width, canvas.height)
  # ctx.fill()

  x = bh * (Math.max(features.roof.inset, 0) + 1)
  y = bh
  w = canvas.width - x * 2

  ctx.lineWidth = 2
  ctx.strokeStyle = "#00184d"
  ctx.fillStyle = "#f4dabe"
  ctx.save()

  # Base Line
  ctx.lineWidth = wobble(3, 2)
  ctx.beginPath()
  ctx.moveTo(0, canvas.height - ctx.lineWidth / 2)
  ctx.lineTo(canvas.width, canvas.height - ctx.lineWidth / 2)
  ctx.stroke()

  # Tile Clipping Mask
  switch features.roof.style
    when "triangular"
      ctx.beginPath()
      ctx.moveTo(x, y + features.roof.h)
      ctx.lineTo(x, y + features.roof.h - bh)
      ctx.lineTo(x + w / 2, y - bh)
      ctx.lineTo(x + w, y + features.roof.h - bh)
      ctx.lineTo(x + w, y + features.roof.h)
      ctx.stroke()

      ctx.beginPath()
      ctx.moveTo(x, y + features.roof.h)
      ctx.lineTo(x + w, y + features.roof.h)
      ctx.lineTo(x + w / 2, y)
      ctx.closePath()
      ctx.stroke()
      ctx.clip()

    when "square"
      ctx.beginPath()
      ctx.moveTo(x, y + features.roof.h)
      ctx.lineTo(x, y + features.roof.h - bh)
      ctx.lineTo(x + w / 4, y - bh)
      ctx.lineTo(x + w * 3/4, y - bh)
      ctx.lineTo(x + w, y + features.roof.h - bh)
      ctx.lineTo(x + w, y + features.roof.h)
      ctx.stroke()

      ctx.beginPath()
      ctx.moveTo(x, y + features.roof.h)
      ctx.lineTo(x + w / 4, y)
      ctx.lineTo(x + w * 3/4, y)
      ctx.lineTo(x + w, y + features.roof.h)
      ctx.closePath()
      ctx.stroke()
      ctx.clip()

  # Tiles
  if features.roof.style
    for i in [0...Math.floor(features.roof.h / bh)]
      for j in [0...Math.floor(w / tw)]
        ctx.beginPath()
        ctx.lineWidth = wobble(3, 2)

        o  = (i % 2) * tw / 2
        fx = o + x + j * tw
        dx = fx + tw
        cy = y + i * bh
        ctx.moveTo(fx, cy)
        ctx.bezierCurveTo(
          fx + tw / 2 - 2, cy + bh,
          fx + tw / 2 + 2, cy + bh,
          dx, cy
        )

        ctx.stroke()

    ctx.restore()

  # Base
  ctx.lineWidth = wobble(4, 2)
  ctx.beginPath()
  ctx.rect(
    0, y + features.roof.h,
    canvas.width, bh * features.roof.base
  )
  ctx.fill()
  ctx.stroke()

  if features.roof.edged
    w = bh * features.roof.edged
    for i in [0...Math.ceil(canvas.width / w)]
      ctx.beginPath()
      ctx.lineWidth = wobble(3, 1)
      ctx.moveTo w * i, y + features.roof.h
      ctx.lineTo w * i, canvas.height
      ctx.stroke()

  posterize(canvas)

  mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
  mask
