smooth    = require("./smooth")

module.exports = (fontSize, process) ->
  canvas = document.createElement("canvas")
  ctx    = canvas.getContext("2d")
  font   = "900 #{fontSize}px Texta"

  hairspace        = ""#String.fromCharCode(8202)
  author           = "S    #{["I", "N", "G", "S"].join(hairspace)}"
  ctx.font         = font

  authorWidth      = ctx.measureText(author).width
  padding          = fontSize / 3
  width            = authorWidth + padding * 2
  height           = fontSize + padding * 1.5

  canvas.width     = width
  canvas.height    = height

  ctx.fillStyle    = "#000"
  ctx.strokeStyle  = "#ddd"
  ctx.textAlign    = "center"
  ctx.textBaseline = "middle"
  ctx.font         = font
  ctx.lineWidth    = fontSize / 8

  ctx.beginPath()
  ctx.rect(
    ctx.lineWidth / 2, ctx.lineWidth / 2,
    width - ctx.lineWidth, height - ctx.lineWidth
  )
  ctx.fill()
  ctx.stroke()

  ctx.fillStyle = "#ddd"

  s = fontSize / 3.0769230769
  x = padding + ctx.measureText("S").width + s + fontSize / 16
  y = height * .5

  ctx.beginPath()
  ctx.moveTo(x - s, y)
  ctx.lineTo(x, y + s)
  ctx.lineTo(x + s, y)
  ctx.lineTo(x, y - s)
  ctx.fill()

  ctx.fillText(author, width / 2, height * .5)

  if process?
    process(canvas, ctx)

  data = ctx.getImageData(0, 0, canvas.width, canvas.height)

  { data, height, width }
