wobble    = require("./wobble")

module.exports = ({ width, height}, padding) ->
  canvas = document.createElement("canvas")
  ctx    = canvas.getContext("2d")

  canvas.width = width
  canvas.height = height

  x = y = padding / 2

  delta = padding / 2
  fuzzy = padding / 6
  limit = (padding - fuzzy) / 2

  ctx.moveTo(x, y)

  while x < canvas.width - padding
    ctx.lineTo(
      x += wobble(delta, fuzzy)
      wobble(limit, fuzzy)
    )

  while y < canvas.height - limit
    ctx.lineTo(
      wobble(canvas.width - limit, fuzzy)
      y += wobble(delta, fuzzy)
    )

  while x > limit
    ctx.lineTo(
      x -= wobble(delta, fuzzy)
      wobble(canvas.height - limit, fuzzy)
    )

  while y > limit
    ctx.lineTo(
      wobble(limit, fuzzy)
      y -= wobble(delta, fuzzy)
    )

  ctx.globalAlpha = 0.9
  ctx.strokeStyle = "#ddd"
  ctx.lineWidth   = padding * 1.3
  ctx.stroke()

  ctx.globalAlpha = 1
  ctx.strokeStyle = "#fff"
  ctx.lineWidth   = padding
  ctx.stroke()

  ctx.beginPath()
  ctx.strokeStyle = "#fff"
  ctx.lineWidth   = delta
  ctx.rect(delta / 2, delta / 2, width - delta, height - delta)
  ctx.stroke()

  StackBlur.canvasRGBA(canvas, 0, 0, canvas.width, canvas.height, padding / 80)

  mask = ctx.getImageData(0, 0, canvas.width, canvas.height)
  mask
