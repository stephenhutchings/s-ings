smooth = require('experiments/smooth')
resample = require('experiments/resample')
shape = require('experiments/shape')
unmask = require('experiments/threshold-to-mask')
cvs = document.createElement('canvas')
ctx = cvs.getContext('2d')
cvs2 = document.createElement('canvas')
ctx2 = cvs2.getContext('2d')
shapes = 60
threshold = _.random(110, 150)
small = cvs2.width = cvs2.height = 360
large = cvs.width = cvs.height = 720

draw = (done, last) ->
  ctx.fillStyle = '#000'
  ctx.beginPath()
  ctx.rect 0, 0, large, large
  ctx.fill()

  ctx.fillStyle = '#fff'
  ctx.beginPath()

  for i in [0...shapes]
    rad = large * 0.333 * (i + 1) / shapes
    dir = if i % 2 then 1 else -1
    shape ctx, rad, dir, large

  ctx.fill()

  smooth cvs, _.random(20, 60), threshold
  smooth cvs, 12, threshold
  StackBlur.canvasRGBA cvs, 0, 0, large, large, 2

  resample ctx, cvs, 2

  if last
    resample ctx, cvs, 2, ->
      mask = ctx.getImageData(0, 0, cvs.width, cvs.height)
      cvs.width = cvs.height = large
      ctx2.clearRect 0, 0, small, small
      ctx2.putImageData last, 0, 0
      r = _.random(220, 255)
      g = _.random(128, 158)
      b = 0
      unmask mask, r, g, b
      ctx.clearRect 0, 0, small, small
      ctx.putImageData mask, small / 4, small / 4
      img = new Image

      img.onload = ->
        ctx2.drawImage img, _.random(-15, 15), _.random(-15, 15)
        done cvs2.toDataURL()

      img.src = cvs.toDataURL()

  else
    data = ctx.getImageData(0, 0, small, small)
    ctx2.putImageData data, 0, 0
    done ctx2.getImageData(0, 0, large, large)


module.exports =
  draw: ->
    step = (count) ->
      if count and count > 0
        window.setTimeout (->
          image = new Image

          onload = ->
            document.body.insertAdjacentElement 'afterBegin', image
            step count - 1
            return

          draw (data) ->
            draw ((res) ->
              image.onload = onload
              image.src = res
              return
            ), data
            return
          return
        ), 1
      return

    step 500
