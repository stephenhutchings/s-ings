wobble    = require("experiments/wobble")
posterize = require("experiments/posterize")

module.exports = (features) ->
  bw = features.brick.w
  bh = features.brick.h
  tw = features.brick.h * 2
  ph = if features.roof.pipe then 40 else 0

  canvas = document.createElement("canvas")
  ctx    = canvas.getContext("2d")

  w = features.floors.w * bw
  h = features.roof.h + ph

  padding = bh * 2 * -Math.min(features.roof.inset, 0)
  canvas.width  = w + padding
  canvas.height = h + bh * (features.roof.base + 1)

  # ctx.fillStyle = "red"
  # ctx.rect(0, 0, canvas.width, canvas.height)
  # ctx.fill()

  x = bh * (Math.max(features.roof.inset, 0) + 1)
  y = bh + ph
  w = canvas.width - x * 2

  ctx.lineWidth = bh / 4
  ctx.strokeStyle = "#000"
  ctx.fillStyle = "#ddd"
  ctx.save()

  # Base Line
  ctx.lineWidth = wobble(features.brick.h / 3, features.brick.h / 4)
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
        ctx.lineWidth = wobble(features.brick.h / 3, features.brick.h / 4)

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

  # Pipe
  yo = Math.random()
  for pipe in [0...features.roof.pipe]
    xo = Math.random()
    pw = 10
    px = x + w * xo
    mh = 1 - Math.abs(0.5 - xo) * 2
    py = y + features.roof.h - ph

    if features.roof.style
      py -= features.roof.h * mh * yo
      ctx.save()
      ctx.fillStyle = "#000"
      ctx.beginPath()
      ctx.arc(px + pw / 2, ph + py, pw, 0, Math.PI * 2)
      ctx.fill()
      ctx.restore()

    ctx.lineWidth = wobble(features.brick.h / 2, features.brick.h / 4)
    ctx.beginPath()
    ctx.rect(px - 1, py, pw + 2, 4)
    ctx.rect(px - 2, py + 4, pw + 4, 8)
    ctx.rect(px, py + 12, pw, ph - 12)
    ctx.fill()
    ctx.stroke()

  # Aerial
  if features.roof.aerial
    m  = _.sample [1, -1]
    aw = 10
    ah = 30
    ax = Math.max(x + w * Math.random(), aw * 2)
    ay = y + features.roof.h - ah
    lw = wobble(features.brick.h / 2, features.brick.h / 4)
    ctx.beginPath()
    # Down
    ctx.moveTo(ax, ay)
    ctx.lineTo(ax, ay + ah)
    # Across
    ctx.moveTo(ax - aw * 4, ay)
    ctx.lineTo(ax + aw * 4, ay)

    for i in [-4 * m..4 * m]
      ex = if i < -2 then 10 else 0
      ctx.moveTo(ax + (i - 0.5) * aw - ex / 2, ay - (aw + ex) * m)
      ctx.lineTo(ax + (i + 0.5) * aw + ex / 2, ay + (aw + ex) * m)

    ctx.strokeStyle = "#ddd"
    ctx.lineWidth = lw * 3
    ctx.stroke()
    ctx.strokeStyle = "#000"
    ctx.lineWidth = lw
    ctx.stroke()

  # Base
  ctx.lineWidth = wobble(features.brick.h / 2, features.brick.h / 4)
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
      ctx.lineWidth = wobble(features.brick.h / 3, features.brick.h / 8)
      ctx.moveTo w * i, y + features.roof.h
      ctx.lineTo w * i, canvas.height
      ctx.stroke()

  posterize(canvas, 0, "grayscale")

  mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
  mask
