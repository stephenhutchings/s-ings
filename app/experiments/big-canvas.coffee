module.exports = ({ width, height, padding } = {}) ->
  canvas        = document.createElement("canvas")
  dpi           = this.devicePixelRatio or 1
  ctx           = canvas.getContext("2d")

  document.body.appendChild canvas

  ww = window.innerWidth
  wh = window.innerHeight

  maxW = parseInt(getComputedStyle(canvas).maxWidth)  or Infinity
  maxH = parseInt(getComputedStyle(canvas).maxHeight) or Infinity

  padding ?= 40
  width   ?= (ww - padding * 2) * dpi
  height  ?= (wh - padding * 5) * dpi

  canvas.width  = width
  canvas.height = height

  sw = Math.min(width , maxW, ww - padding * 2)
  sh = Math.min(height, maxH, wh - padding * 2)

  if sw / width < sh / height
    sh = height * sw / width
  else
    sw = width * sh / height

  _.extend canvas.style,
    width:  "#{sw}px"
    margin: "#{-sh / 2}px #{-sw / 2}px"

  { canvas, ctx }
