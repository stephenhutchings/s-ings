wobble = require("experiments/wobble")
posterize = require("experiments/posterize")

maybe = (chance = 0.5) -> Math.random() > (1 - chance)

frame = (ctx, { x, y, w, h }, features) ->
  bh = h / features.h
  bw = bh * 3

  ctx.beginPath()
  ctx.rect(x, y, w, h)

  if features.topFrame
    ctx.rect(x, y - bh * 2, w, bh * 2)
    for i in [1..Math.floor(w / (bw / 2))]
      ctx.moveTo(x + (i * bw / 2), y - bh * 2)
      ctx.lineTo(x + (i * bw / 2), y)

  if features.bottomFrame
    ctx.rect(x, y + h, w, bh * 2)
    for i in [1..Math.floor(w / (bw / 2))]
      ctx.moveTo(x + (i * bw / 2), y + h)
      ctx.lineTo(x + (i * bw / 2), y + h + bh * 2)

  ctx.fill()

inset = (ctx, { x, y, w, h }, features) ->
  ctx.rect(
    x + features.frameInset / 2
    y + features.frameInset / 2
    w - features.frameInset
    h - features.frameInset
  )

divisions = (ctx, { x, y, w, h }, features) ->
  x += features.frameInset
  y += features.frameInset
  ih = (h - features.frameInset * 1.5) / (features.divisions + 1) - features.frameInset / 2
  iw = (w - features.frameInset * 2)

  isOpen = maybe(0.4)
  openWindows = []

  for j in [features.divisions..0]
    rect = [x, y + (ih + features.frameInset / 2) * j, iw, ih]
    ctx.rect(rect...)

    isOpen = isOpen and maybe(0.8)

    if j <= features.grid
      rects = grid ctx,
        x: x
        y: rect[1] + features.gridInset / 2
        w: iw
        h: ih
      , features

      if isOpen
        openWindows.push(rect) for rect in rects

    else if isOpen
      openWindows.push rect

  ctx.stroke()

  ctx.beginPath()
  ctx.fillStyle = "#00184d"
  ctx.strokeStyle = "#f4dabe"
  ctx.lineWidth = 2

  for rect in openWindows
    [rx, ry, rw, rh] = rect
    oinset = features.frameInset / 1.5
    oinset = 0 if rh <= features.frameInset * 2
    ctx.rect(rx + oinset / 2, ry + oinset / 2, rw - oinset, rh - oinset)

    ctx.fill()
    ctx.stroke() unless oinset

grid = (ctx, {x, y, w, h}, features) ->
  w = (w - features.gridInset * 1.5) / 2
  h = (h - features.gridInset * 1.5) / 2

  rects = [
    [x + features.gridInset / 2, y, w, h]
    [x + features.gridInset / 2, y + h + features.gridInset / 2, w, h]
    [x + features.gridInset + w, y, w, h]
    [x + features.gridInset + w, y + h + features.gridInset / 2, w, h]
  ]

  ctx.rect(rect...) for rect in rects
  rects

gloss = (ctx, {x, y, w, h}, features) ->
  x += features.frameInset
  y += features.frameInset
  w -= features.frameInset * 2
  h -= features.frameInset * 2

  ctx.fillStyle = "#00184d"
  ctx.globalAlpha = 0.085
  ctx.beginPath()
  ctx.moveTo x, y
  ctx.lineTo x + w, y
  ctx.bezierCurveTo(
    x + w, y + h * wobble(0.8, 0.43),
    x, y + h * wobble(0.2, 0.43),
    x, y + h
  )

  ctx.fill()
  ctx.globalAlpha = 1

module.exports = (features, dimensions) ->
  canvas = document.createElement("canvas")
  ctx = canvas.getContext("2d")

  canvas.width = dimensions.w
  canvas.height = dimensions.h

  dimensions.inset = features.frameInset
  dimensions.x = 0
  dimensions.y = 0

  ctx.fillStyle = "#f4dabe"
  ctx.strokeStyle = "#00184d"
  ctx.lineWidth = wobble 3, 1

  frame(ctx, dimensions, features)
  inset(ctx, dimensions, features)
  divisions(ctx, dimensions, features)

  posterize(canvas)

  gloss(ctx, dimensions, features)

  mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
  mask
