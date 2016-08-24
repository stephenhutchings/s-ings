posterize = require("experiments/posterize")
wobble = require("experiments/wobble")

supports = (ctx, escape, features) ->
  ctx.beginPath()
  ctx.rect(0, escape.h, escape.w, escape.gridH)
  ctx.rect(0, escape.h - escape.railH, escape.w, escape.gridH)
  ctx.fill()
  ctx.stroke()

  ctx.beginPath()

  if escape.side is 0
    ctx.moveTo(features.brick.w, escape.h)
    ctx.lineTo(escape.w, escape.h + escape.baseH)
    ctx.lineTo(escape.w, escape.h + escape.baseH + escape.gridH)
    ctx.lineTo(features.brick.w, escape.h + escape.gridH)
  else
    ctx.moveTo(escape.w - features.brick.w, escape.h)
    ctx.lineTo(0, escape.h + escape.baseH)
    ctx.lineTo(0, escape.h + escape.baseH + escape.gridH)
    ctx.lineTo(escape.w - features.brick.w, escape.h + escape.gridH)

  ctx.closePath()
  ctx.fill()
  ctx.stroke()

ladder = (ctx, escape, features) ->
  h = features.brick.h * 3
  w = features.brick.w * 2
  x = if escape.side then features.brick.w else escape.w - w - features.brick.w

  if escape.floor > 0
    ctx.save()

    ctx.fillStyle   = "#f4dabe"
    ctx.beginPath()
    ctx.rect(x - 16, 0, 8, escape.h)
    ctx.rect(x + w + 8, 0, 8, escape.h)
    ctx.fill()

    ctx.fillStyle = "#00184d"
    ctx.globalAlpha = 0.3
    ctx.beginPath()
    ctx.rect(x - 8, 0, w + 16, escape.h / 3)
    ctx.fill()

    ctx.restore()

    ctx.beginPath()
    for i in [0..escape.h / (h + features.brick.h) - 1]
      ctx.clearRect(x, h * i + features.brick.h * (i + 1), w, h)
      ctx.rect(x, h * i + features.brick.h * (i + 1), w, h)

    # ctx.fill()
    ctx.rect(x - 8, 0, w + 16, escape.h)

    ctx.stroke()

bars = (ctx, escape, features) ->
  for i in [0...escape.w / features.brick.h / 2]
    ctx.beginPath()
    ctx.moveTo(i * features.brick.h * 2, escape.h - escape.railH)
    ctx.lineTo(i * features.brick.h * 2, escape.h)
    ctx.lineWidth = wobble(3, 1)
    ctx.stroke()

module.exports = (features, escape, side, floor) ->
  canvas = document.createElement("canvas")
  ctx = canvas.getContext("2d")

  escape.baseH = features.brick.h * 4
  escape.railH = features.brick.h * 14
  escape.gridH = features.brick.h * 2
  escape.side  = side
  escape.floor = floor

  lineWidth   = wobble(3, 1)

  canvas.width  = escape.w + lineWidth / 2
  canvas.height = escape.h + escape.baseH + escape.gridH

  ctx.lineWidth   = lineWidth
  ctx.fillStyle   = "#f4dabe"
  ctx.strokeStyle = "#00184d"

  ladder(ctx, escape, features)
  supports(ctx, escape, features)
  bars(ctx, escape, features)

  posterize(canvas, wobble(5, 1))

  mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
  mask
