shape    = require("experiments/shape")
smooth   = require("experiments/smooth")
resample = require("experiments/resample")
sequence = require("experiments/sequence")
unmask   = require("experiments/threshold-to-mask")

dpi   = window.devicePixelRatio or 1
scale = 2
large = 360 * dpi
small = 180

draw = (done) ->
  cvs = document.createElement("canvas")
  ctx = cvs.getContext("2d")
  cvs.width = cvs.height = large

  ctx.fillStyle = "#000"
  ctx.beginPath()
  ctx.rect 0, 0, large, large
  ctx.fill()

  ctx.fillStyle = "#fff"
  ctx.beginPath()

  shapes = 8 + Math.random() * 8

  for i in [0..shapes]
    shape ctx,
      large * 0.333 * (i + 1) / shapes
      (if i % 2 then 1 else -1)
      large

  ctx.fill()

  smooth cvs, 12 + 40 * Math.random()
  smooth cvs, 12
  StackBlur.canvasRGB cvs, 0, 0, large, large, 2

  data = ctx.getImageData(0, 0, large, large)
  unmask data, 255, 255, 255
  ctx.putImageData data, 0, 0

  resample ctx, cvs, scale

  image = new Image()
  image.onload = -> done(this)
  image.src = cvs.toDataURL()
  image.style.height = image.style.width = small + "px"

module.exports =
  draw: (options, done) ->
    amount =
      Math.floor(window.innerHeight / small) *
      Math.floor(window.innerWidth / small)

    sequence(
      for i in [0...amount]
        -> draw (image) ->
          document.body.insertAdjacentElement "afterBegin", image

    , 0, "Babble").then(done)
