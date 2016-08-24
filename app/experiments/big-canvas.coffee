module.exports = (padding) ->
  canvas        = document.createElement("canvas")
  dpi           = window.devicePixelRatio or 1
  ctx           = canvas.getContext("2d")

  document.body.appendChild canvas

  maxW = parseInt(getComputedStyle(canvas).maxWidth)  or Infinity
  maxH = parseInt(getComputedStyle(canvas).maxHeight) or Infinity

  canvas.width  = Math.min(window.innerWidth  - padding * 2, maxW) * dpi
  canvas.height = Math.min(window.innerHeight - padding * 2, maxH) * dpi

  canvas.style.width  = canvas.width  / dpi + "px"
  canvas.style.height = canvas.height / dpi + "px"
  canvas.style.margin = padding + "px"

  { canvas, ctx }
