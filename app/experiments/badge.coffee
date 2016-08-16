smooth    = require("experiments/smooth")

module.exports = (title, fontSize, process) ->
  canvas = document.createElement("canvas")
  ctx    = canvas.getContext("2d")

  hairspace        = String.fromCharCode(8202)
  author           = "S    #{["I", "N", "G", "S"].join(hairspace)}"
  ctx.font = font  = "bold #{fontSize}px Texta"

  authorWidth      = ctx.measureText(author).width
  titleWidth       = ctx.measureText(title).width
  textWidth        = Math.max authorWidth, titleWidth

  scale = authorWidth / titleWidth
  textWidth = authorWidth
  console.log scale

  padding          = fontSize / 2
  width            = textWidth + padding * 2
  height           = fontSize + padding * 5

  canvas.width     = width
  canvas.height    = height

  ctx.fillStyle    = "#f4dabe"
  ctx.strokeStyle  = "#00184d"

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

  ctx.fillStyle = "#00184d"

  s = fontSize / 3.0769230769
  x = padding + ctx.measureText("S").width + s + fontSize / 16
  y = height * .75

  # if titleWidth > authorWidth
  #   x -= (authorWidth - titleWidth) / 2

  ctx.beginPath()
  ctx.moveTo(x - s, y)
  ctx.lineTo(x, y + s)
  ctx.lineTo(x + s, y)
  ctx.lineTo(x, y - s)
  ctx.fill()

  ctx.beginPath()
  ctx.moveTo(0, height / 2)
  ctx.lineTo(width, height / 2)
  ctx.stroke()

  ctx.fillText(author, width / 2, height * .75)

  ctx.font = font  = "bold #{fontSize * scale}px Texta"
  ctx.fillText(title,  width / 2, height * .25)

  if process?
    process(canvas, ctx)

  data = ctx.getImageData(0, 0, canvas.width, canvas.height)

  { data, height, width }
