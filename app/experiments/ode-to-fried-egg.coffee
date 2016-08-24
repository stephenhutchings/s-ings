shape    = require("experiments/shape")
layer    = require("experiments/layer")
smooth   = require("experiments/smooth")
sequence = require("experiments/sequence")
unmask   = require("experiments/threshold-to-mask")

dpi   = window.devicePixelRatio or 1
small = 180
large = small * 2 * dpi

draw = (done) ->
  parentCanvas = document.createElement("canvas")
  parentContext = parentCanvas.getContext("2d")
  parentCanvas.width = parentCanvas.height = large

  step = (color, size) ->
    cvs  = document.createElement("canvas")
    ctx  = cvs.getContext("2d")

    shapes    = _.random(50, 70)
    threshold = _.random(110, 150)
    offset    = (large - size) / 2
    cvs.width = cvs.height = size

    ctx.fillStyle = "black"
    ctx.beginPath()
    ctx.rect 0, 0, size, size
    ctx.fill()

    ctx.fillStyle = "white"
    ctx.beginPath()

    for i in [0...shapes]
      rad = size * 0.333 * (i + 1) / shapes
      dir = if i % 2 then 1 else -1
      shape ctx, rad, dir, size

    ctx.fill()

    smooth cvs, _.random(20, 60), threshold
    smooth cvs, 12, threshold
    StackBlur.canvasRGBA cvs, 0, 0, size, size, 2

    data = ctx.getImageData(0, 0, size, size)
    unmask data, color...

    layer(parentContext, data, offset, offset)

  sequence [
    -> step([255, 255, 255], large, 0)
    -> step([ _.random(220, 255), _.random(128, 158), 0 ], small * dpi)
    ->
      img = new Image()
      img.onload = -> done(this)
      img.src = parentCanvas.toDataURL()
      img.style.height = img.style.width = small + "px"
  ]

module.exports =
  draw: (c) ->
    amount =
      Math.floor(window.innerHeight / small) *
      Math.floor(window.innerWidth / small)

    sequence([
      (for i in [0...amount]
        -> draw (image) ->
          document.body.insertAdjacentElement "afterBegin", image
      )...
    ], 0, "Frying").then(c)
