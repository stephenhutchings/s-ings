wobble = require("experiments/wobble")
posterize = require("experiments/posterize")

maybe = (chance = 0.5) -> Math.random() > (1 - chance)

frame = (ctx, { x, y, w, h }, features) ->
  bh = h / features.h
  bw = bh * 3

  ctx.beginPath()
  ctx.rect(x, y, w, h)

  if features.topFrame
    ctx.rect(x, 0, w, bh * 2)
    for i in [1..Math.floor(w / (bw / 2))]
      ctx.moveTo(x + (i * bw / 2), 0)
      ctx.lineTo(x + (i * bw / 2), bh * 2)

  if features.bottomFrame
    ctx.rect(x, y + h, w, bh * 2)
    for i in [1..Math.floor(w / (bw / 2))]
      ctx.moveTo(x + (i * bw / 2), y + h)
      ctx.lineTo(x + (i * bw / 2), y + h + bh * 2)

  ctx.fill()
  ctx.stroke()

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
  iw = (w - features.frameInset * 2)
  ih = (h - features.frameInset * 1.5) / (features.divisions + 1) -
       features.frameInset / 2

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

    else
      if j is Math.round((features.divisions + 1) / 2)
        hi = features.frameInset / 2
        hw = 8
        hh = 4
        hx = x + iw / 2 - hw / 2
        hy = y - hh - hi + (ih + hi) * j
        ctx.rect(hx, hy, hw, hh)

      openWindows.push(rect) if isOpen

  ctx.stroke()

  ctx.beginPath()
  ctx.lineWidth = features.frameInset / 6

  if hi
    oh = if features.divisions % 2 is 0 then 0 else hi
    ctx.moveTo x - hi, hy + hh + oh
    ctx.lineTo x + iw + hi, hy + hh + oh
    ctx.stroke()

  ctx.beginPath()
  ctx.fillStyle = "#000"
  ctx.strokeStyle = "#ddd"

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

  ctx.fillStyle = "#000"
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

  bh = dimensions.h / features.h

  frames = _.compact([features.topFrame, features.bottomFrame]).length
  frameH = bh * 2

  canvas.width = dimensions.w
  canvas.height = dimensions.h + frames * frameH

  dimensions.inset = features.frameInset
  dimensions.x = 0
  dimensions.y = if features.topFrame then frameH else 0

  ctx.fillStyle = "#ddd"
  ctx.strokeStyle = "#000"
  ctx.lineWidth = wobble bh / 3, bh / 8

  frame(ctx, dimensions, features)
  inset(ctx, dimensions, features)
  divisions(ctx, dimensions, features)

  posterize(canvas, bh / 4, "grayscale")

  ctx.fillStyle = "#000"
  ctx.globalAlpha = wobble(0.3, 0.2)
  ctx.rect(0, dimensions.y, dimensions.w, frameH / 1.5)
  ctx.rect(0, dimensions.y, frameH / 2, dimensions.h)
  ctx.fill()
  ctx.globalAlpha = 1

  gloss(ctx, dimensions, features)

  mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
  mask
