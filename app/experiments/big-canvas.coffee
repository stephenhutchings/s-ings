module.exports = (padding) ->
  canvas        = document.createElement("canvas")
  dpi           = window.devicePixelRatio or 1
  ctx           = canvas.getContext("2d")
  canvas.width  = (window.innerWidth  - padding * 2) * dpi
  canvas.height = (window.innerHeight - padding * 2) * dpi

  canvas.style.width  = canvas.width  / dpi + "px"
  canvas.style.height = canvas.height / dpi + "px"
  canvas.style.margin = padding + "px"

  document.body.appendChild canvas

  { canvas, ctx }
