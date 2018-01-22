posterize = require("experiments/posterize")
wobble = require("experiments/wobble")
maybe = require("experiments/brick-a-brac/maybe")

module.exports = (features, dimensions) ->
  canvas = document.createElement("canvas")
  ctx = canvas.getContext("2d")

  { outset, incline, kerbH, baseH, baseW } = features.ground

  bh = features.brick.h

  canvas.width  = dimensions.w + outset * 2
  canvas.height = bh * baseH + kerbH + features.ground.h * 3

  ctx.strokeStyle = "#00184d"

  x = 0
  w = dimensions.w + outset * 2
  y = Math.max(bh * baseH - Math.abs(incline), Math.abs(incline)) +
      ctx.lineWidth / 2

  ctx.fillStyle   = "#f4dabe"

  # Base stones
  rects = []
  ctx.beginPath()
  steps = Math.floor(dimensions.w / (bh * baseW))
  bw = dimensions.w / steps
  for i in [0...steps]
    ctx.lineWidth = wobble(3, 1)
    rect = [outset + i * bw, ctx.lineWidth / 2, bw, bh * baseH]
    rects.push rect
    ctx.rect(rect...)

  ctx.fill()
  ctx.stroke()

  ctx.fillStyle   = "#00184d"

  for rect in rects
    ctx.beginPath()
    ctx.globalAlpha = Math.random() * 0.3
    ctx.rect(rect...)
    ctx.fill()

  ctx.globalAlpha = 1

  ctx.lineWidth = wobble(4, 2)
  ctx.fillStyle   = "#f4dabe"

  # Fill mask
  ctx.beginPath()
  ctx.moveTo(x, y + incline)
  ctx.lineTo(x + w, y - incline)
  ctx.lineTo(x + w, y + 20)
  ctx.lineTo(x, y + 20)
  ctx.fill()

  # Kerb top
  ctx.beginPath()
  ctx.moveTo(x,     y + incline)
  ctx.lineTo(x + w, y - incline)
  ctx.stroke()

  # Kerb base
  if maybe()
    ctx.beginPath()
    ctx.moveTo(x + _.random(20),     y + incline + features.ground.kerbH)
    ctx.lineTo(x + w - _.random(20), y - incline + features.ground.kerbH)
    ctx.stroke()

  # Road surface
  ctx.beginPath()
  ctx.globalAlpha = 0.1
  ctx.lineWidth = wobble(12, 4)
  ctx.lineCap = "round"
  dx = features.ground.inset
  for i in [0..features.ground.h]
    x1 = x + dx * i
    y1 = y + incline + features.ground.kerbH + i * wobble(2, 1)
    y2 = y - incline + features.ground.kerbH + i * wobble(2, 1)
    x2 = x + w - dx * i

    ctx.moveTo(wobble(x1, 10), wobble(y1, 10))
    ctx.lineTo(wobble(x2, 10), wobble(y2, 10))

  ctx.stroke()

  posterize(canvas, wobble(4, 1))
  # ctx.beginPath()
  # ctx.rect(0, 0, canvas.width, canvas.height)
  # ctx.fillStyle = "red"
  # ctx.fill()

  mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
  mask
