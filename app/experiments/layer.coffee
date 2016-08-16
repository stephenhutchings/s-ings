# Paints img2's pixels over the top of img1
module.exports = (bottom, data, x = 0, y = 0) ->
  i = 0
  j = 0

  image   = new Image()
  canvas  = document.createElement("canvas")
  context = canvas.getContext("2d")

  canvas.height = data.height
  canvas.width  = data.width

  context.putImageData(data, 0, 0)

  new Promise (resove, reject) ->
    image.onload = ->
      bottom.drawImage(this, x, y)
      resove(this)

    image.src = canvas.toDataURL()
