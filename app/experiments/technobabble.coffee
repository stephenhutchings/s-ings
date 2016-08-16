resample  = require("experiments/resample")
shape     = require("experiments/shape")

cvs = document.createElement('canvas')
ctx = cvs.getContext('2d')
cvs2 = document.createElement('canvas')
ctx2 = cvs2.getContext('2d')
large = cvs.width = cvs.height = 720
small = cvs2.width = cvs2.height = 360

module.exports =
  draw: ->
    draw = (count) ->

      random = (arr) ->
        arr[Math.floor(Math.random() * arr.length)]

      smooth = (r) ->
        StackBlur.canvasRGBA cvs, 0, 0, large, large, r
        fx.threshold()
        return

      ctx.globalCompositeOperation = 'source-over'
      ctx.globalAlpha = 1
      ctx.fillStyle = '#000'
      ctx.beginPath()
      ctx.rect 0, 0, large, large
      ctx.fill()
      ctx.fillStyle = '#fff'
      ctx.beginPath()
      shapes = 8 + Math.random() * 8

      for i in [0..shapes]
        shape ctx,
          large * 0.333 * (i + 1) / shapes
          (if i % 2 then 1 else -1)
          large

      ctx.fill()
      fx = new CanvasEffects(cvs, useWorker: false)
      smooth 12 + 40 * Math.random()
      smooth 12
      StackBlur.canvasRGBA cvs, 0, 0, large, large, 2
      resample ctx, cvs, 2
      data = ctx.getImageData(0, 0, small, small)
      ctx2.putImageData data, 0, 0
      image = new Image()

      image.onload = ->
        document.body.insertAdjacentElement "afterBegin", image
        if count > 0
          window.setTimeout (->
            draw count - 1
          ), 10

      image.src = cvs2.toDataURL()

    draw 500
